import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox();
    }
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<GameCubit, GameState>(
          builder: (context, gameState) {
            if (!gameState.playingState.isPlaying) {
              return const SizedBox();
            }
            final gameMode = gameState.gameMode;
            final difficulty = gameState.difficulty;
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
                        'nickname: ${authState.user?.nickname ?? 'null'}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'levelTimePassed: ${gameState.levelTimePassed.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'difficulty (${GameConstants.difficultyInitialToPeakDuration}s): %${(gameState.difficulty * 100).toInt()}',
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('0.0'),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: gameState.difficulty,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('1.0'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (gameMode is GameModeSingleSpawn) ...[
                        Text(
                          'spawnEvery: ${gameMode.getSpawnOrbsEvery(difficulty).toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                                '${GameModeSingleSpawn.orbsSpawnEveryInitial}'),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: 1 -
                                    ((gameMode.getSpawnOrbsEvery(difficulty) -
                                            GameModeSingleSpawn
                                                .orbsSpawnEveryPeak) /
                                        (GameModeSingleSpawn
                                                .orbsSpawnEveryInitial -
                                            GameModeSingleSpawn
                                                .orbsSpawnEveryPeak)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                                '${GameModeSingleSpawn.orbsSpawnEveryPeak}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Orbs Move Speed: ${gameMode.getSpawnOrbsMoveSpeed(difficulty).toStringAsFixed(2)}',
                        ),
                      ]
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
