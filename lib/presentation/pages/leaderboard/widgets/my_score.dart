import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/pages/fade_route.dart';
import 'package:save_the_potato/presentation/widgets/new_rank_celebration_page.dart';

import 'score_rank_number.dart';

class MyScore extends StatelessWidget {
  const MyScore({
    super.key,
    required this.scoreEntity,
  });

  final OnlineScoreEntity scoreEntity;

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
    return Container(
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
          child: PopupMenuButton<int>(
            onSelected: (item) async {
              switch (item) {
                case 0:
                  context.read<ScoresCubit>().updateNickname();
                case 1:
                  context.read<ScoresCubit>().shareScore(scoreEntity);
                case 2:
                  Navigator.of(context).push(
                    FadeRoute(
                      page: NewRankCelebrationPage(
                        scoreEntity: scoreEntity,
                      ),
                    ),
                  );
                case _:
                  throw Exception('Unknown menu item: $item');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Text('Rename Nickname'),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Share Score'),
              ),
              if (kDebugMode)
                const PopupMenuItem<int>(
                  value: 2,
                  child: Text('Celebrate New Rank'),
                ),
            ],
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
  }
}
