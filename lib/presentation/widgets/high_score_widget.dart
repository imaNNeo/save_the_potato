import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';

class HighScoreWidget extends StatelessWidget {
  const HighScoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScoresCubit, ScoresState>(
      builder: (context, state) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {

              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  top: 12.0,
                  bottom: 12.0,
                  right: 20.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 36,
                      color: Colors.yellow,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Best:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          state.highScore?.representation ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
