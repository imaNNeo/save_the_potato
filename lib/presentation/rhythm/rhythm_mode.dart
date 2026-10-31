import 'package:flutter/foundation.dart';

/// Prototype switch for the rhythm experiments, tucked under the version
/// number in settings. [onBeat] is the default; [off] is the old timing.
/// On the web `?rhythm=` overrides it, on mobile `--dart-define=RHYTHM=`.
enum RhythmMode {
  off('Off (old timing)', 'off'),
  onBeat('On the beat', 'onBeat'),
  inKey('On the beat, in key', 'inKey'),
  melody('Shield plays the melody', 'melody');

  const RhythmMode(this.title, this.key);

  final String title;
  final String? key;

  /// Plays over the current background music and its beat map
  bool get usesGameMusic => this == onBeat || this == inKey;

  /// Plays the new 120 BPM stems instead of the background music
  bool get usesStems => this == melody;

  static final current = ValueNotifier<RhythmMode>(_initial());

  /// The mode of the run being played; changing [current] only applies to
  /// the next run
  static RhythmMode playing = RhythmMode.off;

  static bool get _forced =>
      const String.fromEnvironment('RHYTHM').isNotEmpty ||
      (kIsWeb && Uri.base.queryParameters.containsKey('rhythm'));

  /// The saved choice from settings, unless a flag forces one
  static void restore(String? key) {
    if (_forced || key == null) {
      return;
    }
    current.value = fromKey(key) ?? current.value;
  }

  static RhythmMode? fromKey(String key) {
    for (final mode in RhythmMode.values) {
      if (mode.key == key || mode.name == key) {
        return mode;
      }
    }
    return null;
  }

  static RhythmMode _initial() {
    const fromDefine = String.fromEnvironment('RHYTHM');
    var key = fromDefine;
    if (kIsWeb) {
      key = Uri.base.queryParameters['rhythm'] ?? fromDefine;
    }
    return fromKey(key) ?? RhythmMode.onBeat;
  }

  static void next() {
    final values = RhythmMode.values;
    current.value = values[(current.value.index + 1) % values.length];
  }
}
