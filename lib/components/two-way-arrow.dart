import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/cubit/game_cubit.dart';

import 'player.dart';

class TwoWayArrow extends PositionComponent
    with
        ParentIsA<Player>,
        FlameBlocListenable<GameCubit, GameState>,
        HasPaint {
  late Sprite _arrowSprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _arrowSprite = await Sprite.load('two-way-arrow.png');

    const rotateAmount = pi / 20;
    angle = -rotateAmount;
    add(RotateEffect.to(
      rotateAmount,
      EffectController(
        duration: 0.9,
        alternate: true,
        infinite: true,
      ),
    ));
  }

  @override
  bool listenWhen(previousState, newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(state) {
    super.onNewState(state);
    if (!state.playingState.isGuide) {
      add(OpacityEffect.to(
        0,
        EffectController(duration: 0.5),
        onComplete: () {
          removeFromParent();
        },
      ));
    }
  }

  @override
  void update(double dt) {
    position = parent.size / 2;
    size = parent.size * 1.9;
    anchor = Anchor.center;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _arrowSprite.render(
      canvas,
      size: size,
      overridePaint: paint
        ..colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(0.4),
          BlendMode.srcIn,
        ),
    );
  }
}
