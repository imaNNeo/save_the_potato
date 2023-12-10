import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/cubit/game_cubit.dart';
import 'package:save_the_potato/game_configs.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const manualDisable = false;
    if (!kDebugMode || manualDisable) {
      return const SizedBox();
    }
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        return Container(
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
              Text('spawnEvery: ${state.spawnOrbsEvery.toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('${GameConfigs.initialSpawnOrbsEvery}'),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: 1 -
                          ((state.spawnOrbsEvery -
                                  GameConfigs.spawnOrbsEveryMinimum) /
                              (GameConfigs.initialSpawnOrbsEvery -
                                  GameConfigs.spawnOrbsEveryMinimum)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('${GameConfigs.spawnOrbsEveryMinimum}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
