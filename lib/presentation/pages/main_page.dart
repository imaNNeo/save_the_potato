import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_configs.dart';
import 'package:save_the_potato/presentation/cubit/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/presentation/my_game.dart';
import 'package:save_the_potato/presentation/widgets/debug_panel.dart';
import 'package:save_the_potato/presentation/widgets/game_over_ui.dart';
import 'package:save_the_potato/presentation/widgets/potato_top_bar.dart';
import 'package:save_the_potato/presentation/widgets/rotating_controls.dart';

import 'settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late MyGame _game;

  late GameCubit _gameCubit;
  late SettingsCubit _settingsCubit;

  late StreamSubscription _streamSubscription;

  late PlayingState _previousState;

  @override
  void initState() {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          return Stack(
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
              if (state.showGameOverUI) const GameOverUI(),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(28.0),
                              ),
                            ),
                            title: Text("Settings"),
                            content: SettingsContent(),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
        ? GameConfigs.neutralGradientFrom
        : heatLevel > 0
            ? ColorTween(
                begin: GameConfigs.neutralGradientFrom,
                end: GameConfigs.heatGradientFrom,
              ).lerp(heatLevel / GameConfigs.maxHeatLevel)!
            : ColorTween(
                begin: GameConfigs.neutralGradientFrom,
                end: GameConfigs.coldGradientFrom,
              ).lerp(heatLevel.abs() / GameConfigs.maxHeatLevel)!;
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
