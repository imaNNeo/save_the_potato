import 'package:flutter/foundation.dart';

/// Web-only switches for testing the tutorial
class TutorialFlags {
  /// `?tutorial=1` runs the tutorial even for players who finished it
  static final force = kIsWeb && Uri.base.queryParameters['tutorial'] == '1';

  /// `?tutorialbot=1` plays the tutorial by itself, missing one orb on
  /// purpose, to record videos
  static final bot = kIsWeb && Uri.base.queryParameters['tutorialbot'] == '1';
}
