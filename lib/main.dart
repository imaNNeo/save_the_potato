import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/cubit/game_cubit.dart';
import 'package:save_the_potato/my_game.dart';

import 'game_configs.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameCubit(),
      child: MaterialApp(
        title: 'Save the Potato',
        theme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'Cookies',
              ),
        ),
        home: const MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MyGame _game;

  late GameCubit _gameCubit;

  late StreamSubscription _streamSubscription;

  late PlayingState _previousState;

  @override
  void initState() {
    _gameCubit = context.read<GameCubit>();
    _gameCubit.startGame();
    _game = MyGame(_gameCubit);
    _previousState = _gameCubit.state.playingState;
    _streamSubscription = _gameCubit.stream.listen((state) {
      if (_previousState == PlayingState.none &&
          state.playingState == PlayingState.playing) {
        setState(() {
          _game = MyGame(_gameCubit);
        });
      }
      _previousState = state.playingState;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _game,
            backgroundBuilder: (context) {
              return BlocBuilder<GameCubit, GameState>(
                buildWhen: (prev, current) =>
                    prev.heatLevel != current.heatLevel,
                builder: (context, state) {
                  return BackgroundGradient(heatLevel: state.heatLevel);
                },
              );
            },
          ),
          BlocBuilder<GameCubit, GameState>(
            builder: (context, state) {
              return Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      state.heatLevel.toString(),
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                  if (state.showGameOverUI)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black87,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Game Over',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _gameCubit.restartGame,
                              child: const Text('Play Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (kDebugMode)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Debug Panel:',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'timePassed: ${state.timePassed.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                                'spawnEvery: ${state.spawnOrbsEvery.toStringAsFixed(2)}'),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                    '${GameConfigs.initialSpawnOrbsEvery}'),
                                SizedBox(
                                  width: 200,
                                  child: LinearProgressIndicator(
                                    value: 1 -
                                        ((state.spawnOrbsEvery -
                                                GameConfigs
                                                    .spawnOrbsEveryMinimum) /
                                            (GameConfigs.initialSpawnOrbsEvery -
                                                GameConfigs
                                                    .spawnOrbsEveryMinimum)),
                                  ),
                                ),
                                const Text(
                                    '${GameConfigs.spawnOrbsEveryMinimum}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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
