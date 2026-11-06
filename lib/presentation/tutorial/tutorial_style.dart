import 'package:flutter/foundation.dart';

import 'page_setting.dart';

/// The ways the first-time tutorial can teach, so we can compare them.
enum TutorialStyle {
  /// A see-through shield shows where to turn for the first orbs, then the
  /// help fades out and comes back only after a miss
  ghost,

  /// No help until an orb is about to hit: then time almost stops, the
  /// right spot lights up and time comes back once the shield is there
  slowMo,

  /// Orbs come without help. A hit freezes the game, shows where the
  /// shield should have been and waits for the player to put it there
  ouch;

  static const defaultStyle = TutorialStyle.ghost;

  /// `?tutorial=ghost|slowMo|ouch` on web (or `window.tutorialStyle` set
  /// by the preview page) always runs that tutorial, even for players who
  /// finished it before
  static TutorialStyle? get forced {
    if (!kIsWeb) {
      return null;
    }
    final name =
        Uri.base.queryParameters['tutorial'] ?? pageSetting('tutorialStyle');
    for (final style in values) {
      if (style.name.toLowerCase() == name?.toLowerCase()) {
        return style;
      }
    }
    return null;
  }

  /// `?tutorialbot=1` on web plays the tutorial by itself, missing a couple
  /// of orbs on purpose, to record videos
  static final bot = kIsWeb && Uri.base.queryParameters['tutorialbot'] == '1';
}
