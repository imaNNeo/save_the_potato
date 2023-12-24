import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/cubit/game_cubit.dart';
import 'package:save_the_potato/game_configs.dart';

import 'range_progress_indicator/range_progress_indicator.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox();
    }
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        return SafeArea(
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
                Text('timePassed: ${state.timePassed.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                Text(
                    'difficulty (${GameConfigs.difficultyInitialToPeakDuration}s): %${(state.difficulty * 100).toInt()}'),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('0.0'),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(value: state.difficulty),
                    ),
                    const SizedBox(width: 4),
                    const Text('1.0'),
                  ],
                ),
                const SizedBox(height: 12),
                Text('spawnEvery: ${state.spawnOrbsEvery.toStringAsFixed(2)}'),
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
                            ((state.spawnOrbsEvery -
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
                    'Orbs Move Speed: ${state.spawnOrbsMoveSpeedRange.simpleFormatInt}'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(GameConfigs.orbsMoveSpeedInitial.simpleFormatInt),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 200,
                      child: RangeProgressIndicator(
                        min: GameConfigs.orbsMoveSpeedInitial.min,
                        max: GameConfigs.orbsMoveSpeedPeak.max,
                        range: state.spawnOrbsMoveSpeedRange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(GameConfigs.orbsMoveSpeedPeak.simpleFormatInt),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
