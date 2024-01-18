import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'score_rank_number.dart';

class MyScore extends StatelessWidget {
  const MyScore({
    super.key,
    required this.onTap,
    required this.scoreEntity,
    required this.loading,
  });

  final OnlineScoreEntity scoreEntity;
  final bool loading;
  final VoidCallback onTap;

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
    final rawChild = Container(
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
              onTap: onTap,
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
                        child: Wrap(
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
                            const SizedBox(width: 8),
                            const Text(
                              '(edit)',
                              style: TextStyle(
                                color: GameColors.linkBlueColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
      );
    return BlocListener<ScoresCubit, ScoresState>(
      listener: (context, state) {
        if (state.showAuthDialog) {
          BaseDialog.showAuthDialog(context);
        }
        if (state.showNicknameDialog) {
          BaseDialog.showNicknameDialog(context);
        }
      },
      child: loading ? rawChild.animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          color: Colors.white,
          blendMode: BlendMode.dstOut,
          duration: const Duration(seconds: 2),
          angle: 45,
        ) : rawChild,
      );
  }
}
