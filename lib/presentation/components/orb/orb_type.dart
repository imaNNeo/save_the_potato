
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:save_the_potato/domain/game_constants.dart';

sealed class OrbType {
  const OrbType();

  Future<void> onLoad() async {}

  List<Sprite> get smallSparkleSprites;

  List<Color> get colors;

  Color get baseColor => colors.first;

  bool isFire() => this is FireOrbType;
  bool isIce() => this is IceOrbType;
}

class FireOrbType extends OrbType {
  late List<Sprite> _smallSparkleSprites;

  @override
  Future<void> onLoad() async {
    _smallSparkleSprites = await Future.wait(
      List.generate(2, (i) => Sprite.load('sparkle/sparkle${i + 1}.png')),
    );
    return super.onLoad();
  }

  @override
  List<Color> get colors => GameConstants.redColors;

  @override
  List<Sprite> get smallSparkleSprites => _smallSparkleSprites;
}

class IceOrbType extends OrbType {
  late List<Sprite> _smallSparkleSprites;

  @override
  Future<void> onLoad() async {
    _smallSparkleSprites = await Future.wait(
      List.generate(2, (i) => Sprite.load('snow/snowflake${i + 1}.png')),
    );
    return super.onLoad();
  }

  @override
  List<Color> get colors => GameConstants.blueColors;

  @override
  List<Sprite> get smallSparkleSprites => _smallSparkleSprites;
}

class HeartOrbType extends OrbType {
  late List<Sprite> _smallSparkleSprites;

  @override
  Future<void> onLoad() async {
    _smallSparkleSprites = await Future.wait(
      List.generate(2, (i) => Sprite.load('heart/heart${i + 1}.png')),
    );
    return super.onLoad();
  }

  @override
  List<Color> get colors => GameConstants.pinkColors;

  @override
  List<Sprite> get smallSparkleSprites => _smallSparkleSprites;
}