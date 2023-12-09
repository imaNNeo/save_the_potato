import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ice_fire_game/cubit/game_cubit.dart';
import 'package:ice_fire_game/my_game.dart';

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
          GameWidget(game: _game),
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
