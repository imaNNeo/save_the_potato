import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/presentation/my_game.dart';
import 'package:save_the_potato/presentation/widgets/debug_panel.dart';
import 'package:save_the_potato/presentation/widgets/game_over_ui.dart';
import 'package:save_the_potato/presentation/widgets/game_paused_ui.dart';
import 'package:save_the_potato/presentation/widgets/high_score_widget.dart';
import 'package:save_the_potato/presentation/widgets/potato_top_bar.dart';
import 'package:save_the_potato/presentation/widgets/rotating_controls.dart';
import 'package:save_the_potato/presentation/widgets/settings_pause_icon.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late Key pageRootKey;

  late MyGame _game;

  late GameCubit _gameCubit;
  late SettingsCubit _settingsCubit;

  late StreamSubscription _streamSubscription;

  late PlayingState _previousState;

  @override
  void initState() {
    pageRootKey = UniqueKey();
    _gameCubit = context.read<GameCubit>();
    _settingsCubit = context.read<SettingsCubit>();
    _gameCubit.startGame();
    _game = MyGame(_gameCubit, _settingsCubit);
    _previousState = _gameCubit.state.playingState;
    _streamSubscription = _gameCubit.stream.listen((state) {
      if ((_previousState.isNone || _previousState.isGameOver) &&
          (state.playingState.isPlaying || state.playingState.isGuide)) {
        setState(() {
          _game = MyGame(_gameCubit, _settingsCubit);
        });
      }
      _previousState = state.playingState;
    });
    super.initState();
  }

  void _restartGameWidgets() {
    setState(() {
      pageRootKey = UniqueKey();
      _game = MyGame(_gameCubit, _settingsCubit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameWidget = GameWidget(
      game: _game,
      backgroundBuilder: (context) {
        return BlocBuilder<GameCubit, GameState>(
          buildWhen: (prev, current) => prev.heatLevel != current.heatLevel,
          builder: (context, state) {
            return BackgroundGradient(heatLevel: state.heatLevel);
          },
        );
      },
    );
    return BlocConsumer<GameCubit, GameState>(
      key: pageRootKey,
      listener: (context, state) {
        if (state.restartGame) {
          _restartGameWidgets();
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.playingState.isPlaying,
          onPopInvoked: (didPop) async {
            if (didPop) {
              return;
            }
            _gameCubit.pauseGame();
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                gameWidget,
                const Align(
                  alignment: Alignment.topCenter,
                  child: PotatoTopBar(),
                ),
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: DebugPanel(),
                ),
                RotationControls(
                  showGuide: state.playingState.isGuide,
                  onLeftDown: _gameCubit.onLeftTapDown,
                  onLeftUp: _gameCubit.onLeftTapUp,
                  onRightDown: _gameCubit.onRightTapDown,
                  onRightUp: _gameCubit.onRightTapUp,
                ),
                if (state.playingState.isPaused) const GamePausedUI(),
                if (state.showGameOverUI) const GameOverUI(),
                const Align(
                  alignment: Alignment.topRight,
                  child: SettingsPauseIcon(),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: HighScoreWidget(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}

class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({
    super.key,
    required this.heatLevel,
  });

  final int heatLevel;

  @override
  Widget build(BuildContext context) {
    final isNeutral = heatLevel == 0;

    final gradientFrom = isNeutral
        ? GameConstants.neutralGradientFrom
        : heatLevel > 0
            ? ColorTween(
                begin: GameConstants.neutralGradientFrom,
                end: GameConstants.heatGradientFrom,
              ).lerp(heatLevel / GameConstants.maxHeatLevel)!
            : ColorTween(
                begin: GameConstants.neutralGradientFrom,
                end: GameConstants.coldGradientFrom,
              ).lerp(heatLevel.abs() / GameConstants.maxHeatLevel)!;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            gradientFrom,
            const Color(0xFF000000),
          ],
        ),
      ),
    );
  }
}
