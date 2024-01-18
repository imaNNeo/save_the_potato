import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/widgets/game_round_button.dart';
import 'trophy.dart';
import 'victory_lines.dart';

class NewRankCelebrationPage extends StatelessWidget {
  final OnlineScoreEntity scoreEntity;

  const NewRankCelebrationPage({super.key, required this.scoreEntity});

  @override
  Widget build(Object context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constrants) {
          final width = constrants.maxWidth;
          final trophySize = min(width * 0.5, 200.0);
          return BlocBuilder<ScoresCubit, ScoresState>(
            builder: (context, scoreState) {
              OnlineScoreEntity freshScore;
              if (scoreState.myScore is OnlineScoreEntity &&
                  scoreState.myScore!.score >= scoreEntity.score) {
                freshScore = scoreState.myScore! as OnlineScoreEntity;
              } else {
                freshScore = scoreEntity;
              }
              return Stack(
                children: [
                  const VictoryLines(),
                  Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: 48),
                              const Text(
                                'SAVE THE POTATO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  shadows: [
                                    Shadow(
                                      color: GameColors.gameBlue,
                                      offset: Offset(0, 0),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                              const Text(
                                'score:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                AppUtils.getHighScoreRepresentation(
                                  freshScore.score,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                      Trophy(
                        score: freshScore,
                        size: trophySize,
                      ),
                      Expanded(
                        flex: 4,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 200,
                                child: GameRoundButton(
                                  title: 'SHARE SCORE',
                                  onPressed: () {
                                    BaseDialog.showShareScoreDialog(
                                      context,
                                      context.read<AuthCubit>().state.user!,
                                      freshScore,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
