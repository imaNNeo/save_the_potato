import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'score_rank_number.dart';

class MyScore extends StatelessWidget {
  final ScoreEntity scoreEntity;

  const MyScore({
    super.key,
    required this.scoreEntity,
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: GameColors.getLeaderboardStrokeColor(
        context,
        scoreEntity.isMine,
        scoreEntity.rank,
      ),
      width: 2,
    );
    const borderRadius = Radius.circular(16);
    return BlocListener<ScoresCubit, ScoresState>(
      listener: (context, state) {
        if (state.showAuthDialog) {
          BaseDialog.showAuthDialog(context);
        }
        if (state.showNicknameDialog) {
          BaseDialog.showNicknameDialog(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: borderRadius,
            topRight: borderRadius,
          ),
          border: Border(
            left: borderSide,
            top: borderSide,
            right: borderSide,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 40,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: borderRadius,
                topRight: borderRadius,
              ),
              onTap: context.read<ScoresCubit>().onUserScoreClicked,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 18.0,
                ),
                child: Row(
                  children: [
                    ScoreRankNumber(
                      rank: scoreEntity.rank,
                      size: 48,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        child: Row(
                          children: [
                            Text(
                              scoreEntity.nickname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      AppUtils.getHighScoreRepresentation(scoreEntity.score),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
