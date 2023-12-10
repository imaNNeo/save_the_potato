import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:save_the_potato/cubit/game_cubit.dart';
import 'package:save_the_potato/my_game.dart';
import 'package:save_the_potato/widgets/analog_timer.dart';
import 'package:save_the_potato/widgets/retry_button.dart';

import 'game_configs.dart';
import 'widgets/debug_panel.dart';
import 'widgets/potato_state_bar.dart';

void main() {
  runApp(Phoenix(child: const MyApp()));
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

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late MyGame _game;

  late GameCubit _gameCubit;

  late StreamSubscription _streamSubscription;

  late PlayingState _previousState;

  late AnimationController _gameOverAnimationController;

  @override
  void initState() {
    _gameCubit = context.read<GameCubit>();
    _gameCubit.startGame();
    _game = MyGame(_gameCubit);
    _previousState = _gameCubit.state.playingState;
    _streamSubscription = _gameCubit.stream.listen((state) {
      if ((_previousState.isNone || _previousState.isGameOver) &&
          (state.playingState.isPlaying || state.playingState.isGuide)) {
        setState(() {
          _game = MyGame(_gameCubit);
        });
      }
      _previousState = state.playingState;
    });
    _gameOverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gameOverAnimationController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      backgroundColor: Colors.black,
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
          BlocConsumer<GameCubit, GameState>(
            listener: (context, state) {
              if (state.showGameOverUI &&
                  !_gameOverAnimationController.isAnimating) {
                _gameOverAnimationController.forward();
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 40.0, left: 24, right: 18),
                      child: PotatoStateBar(),
                    ),
                  ),
                  if (state.showGameOverUI)
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: Tween<double>(begin: 0.0, end: 16.0).transform(
                          _gameOverAnimationController.value,
                        ),
                        sigmaY: Tween<double>(begin: 0.0, end: 16.0).transform(
                          _gameOverAnimationController.value,
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black.withOpacity(
                          Tween<double>(begin: 0.0, end: 0.7).transform(
                            _gameOverAnimationController.value,
                          ),
                        ),
                      ),
                    ),
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: DebugPanel(),
                  ),
                  Align(
                    alignment: AlignmentTween(
                      begin: Alignment.bottomRight,
                      end: Alignment.center,
                    ).transform(_gameOverAnimationController.value),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: AnalogTimer(
                          time: state.timePassed,
                          isGameOverStyle: state.showGameOverUI,
                          size: Tween<double>(
                            begin: 150,
                            end: 300,
                          ).transform(_gameOverAnimationController.value),
                        ),
                      ),
                    ),
                  ),
                  if (state.showGameOverUI)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: isPortrait ? 460.0 : 0,
                          left: isPortrait ? 0 : 460.0,
                        ),
                        child: ReplyButton(onPressed: () {
                          Phoenix.rebirth(context);
                        }),
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
    _gameOverAnimationController.dispose();
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
