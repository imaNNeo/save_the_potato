import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/presentation/widgets/mode_switcher.dart';

/// The title above the potato on the home screen: the game's name in the
/// infinite mode, or the picked level and its song's name, lifted above the
/// ring of level beads
class GuideTitle extends PositionComponent
    with
        HasGameReference<PotatoGame>,
        FlameBlocListenable<GameCubit, GameState>,
        ParentIsA<Potato> {
  GuideTitle({this.color = const Color(0xB2FFFFFF)}) : super();

  late TextComponent _textComponent;
  late TextComponent _songComponent;

  final Color color;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    add(
      _textComponent = TextComponent(
        text: 'SAVE THE POTATO',
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(fontFamily: 'Cookies', fontSize: 36, color: color),
        ),
      ),
    );
    add(_songComponent = TextComponent(text: '', anchor: Anchor.center));
    mounted.then((_) => _showMode(bloc.state));
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState ||
      previousState.level != newState.level;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (!state.playingState.isGuide) {
      removeFromParent();
      return;
    }
    _showMode(state);
  }

  void _showMode(GameState state) {
    final level = state.level;
    _textComponent.text = level == null ? 'SAVE THE POTATO' : 'LEVEL $level';
    _songComponent.text = level == null ? '' : state.song.name.toUpperCase();
    _songComponent.textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'Cookies',
        fontSize: 22,
        color: Color(state.song.colors.first),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    size = _textComponent.size;
    position = parent.size / 2;
    final levelsMode = _songComponent.text.isNotEmpty;
    // Above the bead ring in the levels mode
    final y = levelsMode
        ? -ModeSwitcher.ringRadius - 78
        : -_textComponent.size.y * 3;
    _textComponent.position = Vector2(_textComponent.width / 2, y);
    _songComponent.position = Vector2(_textComponent.width / 2, y + 34);
  }
}
