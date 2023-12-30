import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/cubit/game_cubit.dart';
import 'package:save_the_potato/presentation/my_game.dart';

class GuideTitle extends PositionComponent
    with
        HasGameRef<MyGame>,
        FlameBlocListenable<GameCubit, GameState>,
        ParentIsA<Potato> {
  GuideTitle({
    this.color = const Color(0xB2FFFFFF),
  }) : super();

  late TextComponent _textComponent;
  late TextPaint _textPaint;

  final Color color;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    _textPaint = TextPaint(
      style: TextStyle(
        fontFamily: 'Cookies',
        fontSize: 36,
        color: color,
      ),
    );
    add(_textComponent = TextComponent(
      text: 'SAVE THE POTATO',
      anchor: Anchor.center,
      textRenderer: _textPaint,
    ));
  }

  @override
  bool listenWhen(previousState, newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(state) {
    super.onNewState(state);
    if (!state.playingState.isGuide) {
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    size = _textComponent.size;
    position = parent.size / 2;
    _textComponent.position = Vector2(
      _textComponent.width / 2,
      -_textComponent.size.y * 3,
    );
  }
}
