import 'package:flutter/foundation.dart';

/// Prototype switch for the rhythm experiments. [off] is the game as it was
/// before; [onBeat] is the default. Pick one on the home screen, with `?rhythm=` on the web, or with
/// `--dart-define=RHYTHM=` on mobile.
enum RhythmMode {
  off('Off (old timing)', 'off'),
  onBeat('On the beat', 'onBeat'),
  inKey('On the beat, in key', 'inKey'),
  melody('Shield plays the melody', 'melody'),
  drumBell('Fire drum, ice bell', 'drumBell'),
  streakSong('Streak builds the song', 'streakSong');

  const RhythmMode(this.title, this.key);

  final String title;
  final String? key;

  /// Plays over the current background music and its beat map
  bool get usesGameMusic => this == onBeat || this == inKey;

  /// Plays the new 120 BPM stems instead of the background music
  bool get usesStems =>
      this == melody || this == drumBell || this == streakSong;

  static final current = ValueNotifier<RhythmMode>(_initial());

  static RhythmMode _initial() {
    const fromDefine = String.fromEnvironment('RHYTHM');
    var key = fromDefine;
    if (kIsWeb) {
      key = Uri.base.queryParameters['rhythm'] ?? fromDefine;
    }
    return RhythmMode.values.firstWhere(
      (m) => m.key == key || m.name == key,
      orElse: () => RhythmMode.onBeat,
    );
  }

  static void next() {
    final values = RhythmMode.values;
    current.value = values[(current.value.index + 1) % values.length];
  }
}
