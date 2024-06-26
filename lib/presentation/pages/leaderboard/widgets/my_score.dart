import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/pages/fade_route.dart';
import 'package:save_the_potato/presentation/widgets/new_rank_celebration_page.dart';
import 'package:save_the_potato/service_locator.dart';

import 'score_rank_number.dart';

class MyScore extends StatelessWidget {
  MyScore({
    super.key,
    required this.scoreEntity,
  });

  final OnlineScoreEntity scoreEntity;
  final analyticsHelper = getIt.get<AnalyticsHelper>();

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
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: borderRadius,
            topRight: borderRadius,
          ),
          child: Material(
            color: Colors.transparent,
            child: PopupMenuButton<int>(
              onOpened: () {
                final user = context.read<AuthCubit>().state.user;
                bool isAnonymous =
                    user == null || user.type == UserType.anonymous;
                analyticsHelper.logLeaderboardMyScoreClick(isAnonymous);
              },
              onSelected: (item) async {
                switch (item) {
                  case 0:
                    analyticsHelper.logRenameNickname(EventSource.leaderboard);
                    context.read<ScoresCubit>().updateNickname();
                  case 1:
                    analyticsHelper.logShareMyScore(EventSource.leaderboard);
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
                  child: _MenuRow(
                    title: 'Rename Nickname',
                    iconSvgAssetName: 'user_pen.svg',
                  ),
                ),
                const PopupMenuItem<int>(
                  value: 1,
                  child: _MenuRow(
                    title: 'Share Score',
                    iconSvgAssetName: 'share.svg',
                  ),
                ),
                if (kDebugMode)
                  const PopupMenuItem<int>(
                    value: 2,
                    child:
                    _MenuRow(
                      title: 'Celebrate New Rank',
                      iconSvgAssetName: 'party_horn.svg',
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 18.0,
                  top: 18.0,
                  bottom: 18.0,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                        'assets/images/icons/menu_dots_vertical.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        )),
                    const SizedBox(width: 6),
                    ScoreRankNumber(
                      rank: scoreEntity.rank,
                      size: 48,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
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
                        ],
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
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    super.key,
    required this.title,
    required this.iconSvgAssetName,
  });

  final String title;
  final String iconSvgAssetName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/icons/$iconSvgAssetName',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Colors.black,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
