import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'rhythm_mode.dart';

/// Prototype only: tap to cycle the rhythm modes between runs
class RhythmModePicker extends StatelessWidget {
  const RhythmModePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GameCubit, GameState, bool>(
      selector: (state) =>
          !state.playingState.isPlaying && !state.playingState.isPaused,
      builder: (context, visible) {
        if (!visible) {
          return const SizedBox();
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 72),
            child: ValueListenableBuilder<RhythmMode>(
              valueListenable: RhythmMode.current,
              builder: (context, mode, _) => Material(
                color: Colors.black54,
                shape: const StadiumBorder(
                  side: BorderSide(color: Colors.white24),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: RhythmMode.next,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mode.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.swap_horiz,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
