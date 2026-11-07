import 'package:flutter_soloud/flutter_soloud.dart';

import 'sound_backend.dart';

/// flutter_soloud, used everywhere but the web
class SoLoudBackend implements SoundBackend {
  late final SoLoud _soLoud;

  @override
  Future<void> init() async {
    _soLoud = SoLoud.instance;
    await _soLoud.init();
    // The stems alone take 7 voices
    _soLoud.setMaxActiveVoiceCount(40);
  }

  @override
  Future<Object> load(String assetPath) => _soLoud.loadAsset(assetPath);

  @override
  Future<void> dispose(Object source) =>
      _soLoud.disposeSource(source as AudioSource);

  @override
  void play(
    Object source, {
    required double volume,
    double pan = 0,
    double speed = 1,
  }) {
    if (speed == 1) {
      _soLoud.play(source as AudioSource, volume: volume, pan: pan);
      return;
    }
    final handle = _soLoud.play(
      source as AudioSource,
      volume: volume,
      pan: pan,
      paused: true,
    );
    _soLoud.setRelativePlaySpeed(handle, speed);
    _soLoud.setPause(handle, false);
  }

  @override
  BackendMusic playMusic(Map<String, (Object, double)> stems) {
    final group = _soLoud.createVoiceGroup();
    final handles = <String, SoundHandle>{};
    for (final MapEntry(key: name, value: (source, volume)) in stems.entries) {
      final handle = _soLoud.play(
        source as AudioSource,
        volume: volume,
        looping: true,
        paused: true,
      );
      _soLoud.setProtectVoice(handle, true);
      handles[name] = handle;
    }
    _soLoud.addVoicesToGroup(group, handles.values.toList());
    // Start them all on the same sample
    _soLoud.setPause(group, false);
    return _SoLoudMusic(_soLoud, group, handles);
  }
}

class _SoLoudMusic implements BackendMusic {
  _SoLoudMusic(this._soLoud, this._group, this._handles);

  final SoLoud _soLoud;
  final SoundHandle _group;
  final Map<String, SoundHandle> _handles;
  bool _stopped = false;

  SoundHandle? get _first {
    if (_stopped || _handles.isEmpty) {
      return null;
    }
    final handle = _handles.values.first;
    return _soLoud.getIsValidVoiceHandle(handle) ? handle : null;
  }

  @override
  bool get isPlaying => _first != null;

  @override
  double? get position {
    final handle = _first;
    if (handle == null) {
      return null;
    }
    return _soLoud.getPosition(handle).inMicroseconds / 1e6;
  }

  @override
  void seek(double seconds) {
    if (_stopped) {
      return;
    }
    final time = Duration(microseconds: (seconds * 1e6).round());
    _soLoud.setPause(_group, true);
    for (final handle in _handles.values) {
      if (_soLoud.getIsValidVoiceHandle(handle)) {
        _soLoud.seek(handle, time);
      }
    }
    _soLoud.setPause(_group, false);
  }

  @override
  void setPaused(bool paused) {
    if (!_stopped) {
      _soLoud.setPause(_group, paused);
    }
  }

  @override
  void fade(String stem, double volume, Duration duration) {
    final handle = _handles[stem];
    if (_stopped || handle == null || !_soLoud.getIsValidVoiceHandle(handle)) {
      return;
    }
    _soLoud.fadeVolume(handle, volume, duration);
  }

  @override
  void stop() {
    if (_stopped) {
      return;
    }
    _stopped = true;
    for (final handle in _handles.values) {
      _soLoud.stop(handle);
    }
    _soLoud.destroyVoiceGroup(_group);
  }
}
