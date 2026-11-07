import 'sound_backend_soloud.dart';
import 'sound_backend_stub.dart'
    if (dart.library.js_interop) 'sound_backend_web.dart';

/// What the game needs from an audio engine: one-shot sounds, and a set of
/// looping music stems that play in step.
///
/// Phones and desktop apps use flutter_soloud. On the web flutter_soloud
/// mixes on the page's main thread (unless the page is cross-origin
/// isolated, which the game's hosts are not), so every frame that takes
/// longer than its audio buffer leaves a gap in the sound and crackles.
/// There the browser's own Web Audio graph plays the sounds instead, on its
/// own audio thread.
abstract class SoundBackend {
  /// The backend for this platform
  static SoundBackend create() => createWebSoundBackend() ?? SoLoudBackend();

  /// Starts the engine
  Future<void> init();

  /// Loads and decodes an asset (a path under `assets/`)
  Future<Object> load(String assetPath);

  Future<void> dispose(Object source);

  /// Plays [source] once. [speed] also changes its pitch, [pan] goes from
  /// -1 (left) to 1 (right).
  void play(
    Object source, {
    required double volume,
    double pan = 0,
    double speed = 1,
  });

  /// Starts [stems] looping together, from the same sample. Each one gets
  /// its own volume.
  BackendMusic playMusic(Map<String, (Object source, double volume)> stems);
}

/// Stems started by [SoundBackend.playMusic]
abstract class BackendMusic {
  /// Whether it still plays (stopping it ends it)
  bool get isPlaying;

  /// Where the first stem is, in seconds of the file (it wraps when it
  /// loops)
  double? get position;

  /// Moves all the stems to [seconds] into the loop
  void seek(double seconds);

  void setPaused(bool paused);

  /// Fades [stem]'s volume to [volume], linearly
  void fade(String stem, double volume, Duration duration);

  void stop();
}
