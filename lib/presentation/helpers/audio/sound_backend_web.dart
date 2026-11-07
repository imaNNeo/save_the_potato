import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'sound_backend.dart';

/// On the web the browser's Web Audio graph plays the sounds: it mixes on
/// its own audio thread, so a slow frame (the first frames compile shaders,
/// which takes long on Windows) can't leave gaps in the sound, and it
/// decodes files off the main thread too.
///
/// `?audio=soloud` keeps flutter_soloud, to compare.
SoundBackend? createWebSoundBackend() {
  if (Uri.base.queryParameters['audio'] == 'soloud') {
    return null;
  }
  return WebAudioBackend();
}

/// Plays sounds like flutter_soloud does, so they sound the same: a voice at
/// pan 0 gets cos(45°) on each channel, and the mix is clipped to [-1, 1].
class WebAudioBackend implements SoundBackend {
  late final web.AudioContext _context;

  /// Every voice goes in here
  late final web.GainNode _mix;

  static const _unlockEvents = [
    'pointerdown',
    'pointerup',
    'touchend',
    'click',
    'keydown',
  ];
  JSFunction? _unlock;

  @override
  Future<void> init() async {
    _context = web.AudioContext(
      web.AudioContextOptions(latencyHint: 'interactive'.toJS),
    );
    _mix = _context.createGain();
    // A two point curve is a straight line that holds its ends: a hard clip
    final clip = _context.createWaveShaper()
      ..curve = Float32List.fromList([-1, 1]).toJS;
    _mix.connect(clip);
    clip.connect(_context.destination);
    _listenForUnlock();
  }

  /// Browsers start the audio suspended until the player touches the page
  void _listenForUnlock() {
    if (_context.state == 'running') {
      return;
    }
    final unlock = ((web.Event _) {
      if (_context.state == 'running') {
        _stopListening();
        return;
      }
      _context.resume().toDart.then((_) {
        if (_context.state == 'running') {
          _stopListening();
        }
      }, onError: (_) => null);
    }).toJS;
    _unlock = unlock;
    for (final type in _unlockEvents) {
      web.window.addEventListener(
        type,
        unlock,
        web.AddEventListenerOptions(capture: true),
      );
    }
  }

  void _stopListening() {
    final unlock = _unlock;
    if (unlock == null) {
      return;
    }
    _unlock = null;
    for (final type in _unlockEvents) {
      web.window.removeEventListener(
        type,
        unlock,
        web.EventListenerOptions(capture: true),
      );
    }
  }

  @override
  Future<Object> load(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    // decodeAudioData takes over the buffer, so it gets its own copy
    final bytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return _context.decodeAudioData(bytes.buffer.toJS).toDart;
  }

  @override
  Future<void> dispose(Object source) async {}

  /// A gain for [volume], then the pan, into the mix. Returns the gain, and
  /// what takes the voice's nodes out of the graph.
  (web.GainNode, void Function()) _voice(
    int channels,
    double volume,
    double pan,
  ) {
    final gain = _context.createGain()..gain.value = volume;
    final angle = (pan.clamp(-1.0, 1.0) + 1) * pi / 4;
    final left = _context.createGain()..gain.value = cos(angle);
    final right = _context.createGain()..gain.value = sin(angle);
    final merger = _context.createChannelMerger(2);
    if (channels >= 2) {
      final splitter = _context.createChannelSplitter(2);
      gain.connect(splitter);
      splitter.connect(left, 0);
      splitter.connect(right, 1);
    } else {
      gain.connect(left);
      gain.connect(right);
    }
    left.connect(merger, 0, 0);
    right.connect(merger, 0, 1);
    merger.connect(_mix);
    void release() {
      for (final node in <web.AudioNode>[gain, left, right, merger]) {
        node.disconnect();
      }
    }

    return (gain, release);
  }

  @override
  void play(
    Object source, {
    required double volume,
    double pan = 0,
    double speed = 1,
  }) {
    final buffer = source as web.AudioBuffer;
    final (gain, release) = _voice(buffer.numberOfChannels, volume, pan);
    final node = _context.createBufferSource()
      ..buffer = buffer
      ..playbackRate.value = speed;
    node.connect(gain);
    node.onended = ((web.Event _) {
      node.disconnect();
      release();
    }).toJS;
    node.start();
  }

  @override
  BackendMusic playMusic(Map<String, (Object, double)> stems) {
    final music = _WebMusic(this, {
      for (final MapEntry(key: name, value: (source, volume)) in stems.entries)
        name: _Stem(
          source as web.AudioBuffer,
          _voice(source.numberOfChannels, volume, 0),
          volume,
        ),
    });
    music._start(0);
    return music;
  }
}

class _Stem {
  _Stem(this.buffer, (web.GainNode, void Function()) voice, double volume)
    : gain = voice.$1,
      release = voice.$2,
      _to = volume,
      _from = volume;

  final web.AudioBuffer buffer;
  final web.GainNode gain;
  final void Function() release;
  web.AudioBufferSourceNode? node;

  // The current fade, in the context's time
  double _from, _to;
  double _fromTime = 0, _toTime = 0;

  double volumeAt(double time) {
    if (time >= _toTime || _toTime <= _fromTime) {
      return _to;
    }
    final t = ((time - _fromTime) / (_toTime - _fromTime)).clamp(0.0, 1.0);
    return _from + (_to - _from) * t;
  }

  void fade(double now, double volume, double seconds) {
    final current = volumeAt(now);
    final param = gain.gain;
    param.cancelScheduledValues(now);
    param.setValueAtTime(current, now);
    if (seconds > 0) {
      param.linearRampToValueAtTime(volume, now + seconds);
    } else {
      param.setValueAtTime(volume, now);
    }
    _from = current;
    _to = volume;
    _fromTime = now;
    _toTime = now + seconds;
  }
}

class _WebMusic implements BackendMusic {
  _WebMusic(this._backend, this._stems);

  final WebAudioBackend _backend;
  final Map<String, _Stem> _stems;

  web.AudioContext get _context => _backend._context;

  bool _stopped = false;

  /// Where in the loop it was when it was paused
  double? _pausedAt;

  /// When the stems started, and from where in the loop
  double _startTime = 0;
  double _startOffset = 0;

  double get _loopSeconds =>
      _stems.isEmpty ? 0 : _stems.values.first.buffer.duration.toDouble();

  void _start(double offset) {
    _stopNodes();
    final loop = _loopSeconds;
    if (loop <= 0) {
      return;
    }
    offset %= loop;
    // The same start time for all, so they play in step
    final when = _context.currentTime.toDouble();
    for (final stem in _stems.values) {
      final node = _context.createBufferSource()
        ..buffer = stem.buffer
        ..loop = true;
      node.connect(stem.gain);
      node.start(when, offset);
      stem.node = node;
    }
    _startTime = when;
    _startOffset = offset;
  }

  void _stopNodes() {
    for (final stem in _stems.values) {
      final node = stem.node;
      if (node == null) {
        continue;
      }
      node.stop();
      node.disconnect();
      stem.node = null;
    }
  }

  @override
  bool get isPlaying => !_stopped;

  @override
  double? get position {
    if (_stopped) {
      return null;
    }
    final paused = _pausedAt;
    if (paused != null) {
      return paused;
    }
    final loop = _loopSeconds;
    if (loop <= 0) {
      return null;
    }
    final elapsed = _context.currentTime.toDouble() - _startTime;
    return (_startOffset + max(0.0, elapsed)) % loop;
  }

  @override
  void seek(double seconds) {
    if (_stopped) {
      return;
    }
    if (_pausedAt != null) {
      _pausedAt = seconds % _loopSeconds;
      return;
    }
    _start(seconds);
  }

  @override
  void setPaused(bool paused) {
    if (_stopped || paused == (_pausedAt != null)) {
      return;
    }
    if (paused) {
      _pausedAt = position;
      _stopNodes();
    } else {
      final at = _pausedAt!;
      _pausedAt = null;
      _start(at);
    }
  }

  @override
  void fade(String stem, double volume, Duration duration) {
    final s = _stems[stem];
    if (_stopped || s == null) {
      return;
    }
    s.fade(
      _context.currentTime.toDouble(),
      volume,
      duration.inMicroseconds / 1e6,
    );
  }

  @override
  void stop() {
    if (_stopped) {
      return;
    }
    _stopped = true;
    _stopNodes();
    for (final stem in _stems.values) {
      stem.release();
    }
  }
}
