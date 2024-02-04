import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';

sealed class OrbType {
  OrbType();

  late Paint _headPaint;

  Future<void> onLoad() async {
    _headPaint = Paint();
  }

  List<Sprite> get smallSparkleSprites;

  List<Color> get colors;

  Color get baseColor => colors.first;

  void update(double dt) {}

  void drawHead(Canvas canvas, Vector2 size) {
    final offset = (size / 2).toOffset();
    final radius = size.x / 2;
    canvas.drawCircle(
      offset,
      radius,
      _headPaint
        ..color = colors.last.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    canvas.drawCircle(
      offset,
      radius,
      _headPaint
        ..color = colors.last.withOpacity(1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    canvas.drawCircle(
      offset,
      radius,
      _headPaint
        ..color = colors.last.withOpacity(1)
        ..maskFilter = null,
    );
    canvas.drawCircle(
      offset,
      radius * 0.75,
      _headPaint
        ..color = Colors.white.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  bool isFire() => this is FireOrbType;

  bool isIce() => this is IceOrbType;

  bool isHeart() => this is HeartOrbType;
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
    _headPaint = Paint();
    return super.onLoad();
  }

  @override
  List<Color> get colors => GameConstants.blueColors;

  @override
  List<Sprite> get smallSparkleSprites => _smallSparkleSprites;
}

class HeartOrbType extends OrbType {
  late List<Sprite> _smallSparkleSprites;
  late Sprite heartSprite;

  double rotation = 0;

  @override
  Future<void> onLoad() async {
    _smallSparkleSprites = await Future.wait(
      List.generate(2, (i) => Sprite.load('heart/heart${i + 1}.png')),
    );
    heartSprite = await Sprite.load('heart/heart1.png');
    return super.onLoad();
  }

  @override
  List<Color> get colors => GameConstants.pinkColors;

  @override
  List<Sprite> get smallSparkleSprites => _smallSparkleSprites;

  @override
  void update(double dt) {
    rotation += dt * 2;
    super.update(dt);
  }
  @override
  void drawHead(Canvas canvas, Vector2 size) {
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(rotation);
    heartSprite.render(
      canvas,
      size: size,
      anchor: Anchor.center,
      overridePaint: Paint()
        ..colorFilter = ColorFilter.mode(
          colors.last,
          BlendMode.srcIn,
        ),
    );
    canvas.translate(0, 0);
  }
}
