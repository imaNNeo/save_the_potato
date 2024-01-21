import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/service_locator.dart';

class HighScoreShareDialogContent extends StatelessWidget {
  HighScoreShareDialogContent({
    super.key,
    required this.userEntity,
    required this.scoreEntity,
  }) : super();

  final UserEntity userEntity;
  final OnlineScoreEntity scoreEntity;

  final analyticsHelper = getIt.get<AnalyticsHelper>();

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: 'Roboto'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: '',
              children: <TextSpan>[
                const TextSpan(text: 'Your nickname is currently '),
                TextSpan(
                  text: '${userEntity.nickname}\n',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: GameColors.gameBlue,
                        offset: Offset(0, 0),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const TextSpan(
                  text: 'Want to update it before sharing your score?',
                ),
                if (userEntity.type == UserType.anonymous)
                  const TextSpan(
                    text: ' Remember, you need to be signed in to change it.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    analyticsHelper.logRenameNickname(EventSource.celebrateHighScore);
                    Navigator.of(context).pop();
                    context.read<ScoresCubit>().updateNickname();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Update it',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    analyticsHelper.logShareMyScore(EventSource.celebrateHighScore);
                    Navigator.of(context).pop();
                    context.read<ScoresCubit>().shareScore(scoreEntity);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
