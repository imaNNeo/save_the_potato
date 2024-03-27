import 'dart:ui';

import 'package:save_the_potato/domain/game_constants.dart';

enum ColorType {
  red,
  blue,
  green,
  pink;

  List<Color> get colors => switch (this) {
    ColorType.red => GameConstants.redColors,
    ColorType.blue => GameConstants.blueColors,
    ColorType.green => GameConstants.greenColors,
    ColorType.pink => GameConstants.pinkColors,
  };

  Color get baseColor => colors.first;

  Color get intenseColor => colors.last;
}