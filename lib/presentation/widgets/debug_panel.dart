import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_configs.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game_cubit.dart';

import 'range_progress_indicator/range_progress_indicator.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<GameCubit, GameState>(
          builder: (context, gameState) {
            if (!gameState.playingState.isPlaying) {
              return const SizedBox();
            }
            if (!kDebugMode) {
              return const SizedBox();
            }
            return DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'RobotoMono',
              ),
              child: SafeArea(
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
                      const SizedBox(height: 24),
                      Text(
                          'nickname: ${authState.user?.nickname ?? 'null'}'),
                      const SizedBox(height: 12),
                      Text(
                          'timePassed: ${gameState.timePassed.toStringAsFixed(2)}'),
                      const SizedBox(height: 12),
                      Text(
                          'difficulty (${GameConfigs.difficultyInitialToPeakDuration}s): %${(gameState.difficulty * 100).toInt()}'),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('0.0'),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                                value: gameState.difficulty),
                          ),
                          const SizedBox(width: 4),
                          const Text('1.0'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                          'spawnEvery: ${gameState.spawnOrbsEvery.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('${GameConfigs.orbsSpawnEveryInitial}'),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: 1 -
                                  ((gameState.spawnOrbsEvery -
                                          GameConfigs.orbsSpawnEveryPeak) /
                                      (GameConfigs.orbsSpawnEveryInitial -
                                          GameConfigs.orbsSpawnEveryPeak)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('${GameConfigs.orbsSpawnEveryPeak}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                          'Orbs Move Speed: ${gameState.spawnOrbsMoveSpeedRange.simpleFormatInt}'),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              GameConfigs.orbsMoveSpeedInitial.simpleFormatInt),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 200,
                            child: RangeProgressIndicator(
                              min: GameConfigs.orbsMoveSpeedInitial.min,
                              max: GameConfigs.orbsMoveSpeedPeak.max,
                              range: gameState.spawnOrbsMoveSpeedRange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(GameConfigs.orbsMoveSpeedPeak.simpleFormatInt),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
