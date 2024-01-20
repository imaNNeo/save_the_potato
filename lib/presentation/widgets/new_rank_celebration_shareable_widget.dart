import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'trophy.dart';
import 'victory_lines.dart';

class NewRankCelebrationShareableWidget extends StatelessWidget {
  final OnlineScoreEntity scoreEntity;

  static const preferredWidth = 1080.0;
  static const preferredHeight = 1350.0;

  const NewRankCelebrationShareableWidget({
    super.key,
    required this.scoreEntity,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: preferredWidth / preferredHeight,
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Cookies'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return ClipRect(
              child: Stack(
                children: [
                  Container(color: Colors.black),
                  const VictoryLines(
                    animated: false,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: width * 0.15),
                        Text(
                          AppUtils.getHighScoreRepresentation(scoreEntity.score),
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
                        SizedBox(height: width * 0.05),
                        Trophy(
                          score: scoreEntity,
                          size: width * 0.42,
                        ),
                        SizedBox(height: width * 0.07),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/logo/logo-512.png',
                            width: width * 0.2,
                          ),
                        ),
                        SizedBox(height: width * 0.05),
                        const Text(
                          'SAVE THE POTATO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            shadows: [
                              Shadow(
                                color: GameColors.gameBlue,
                                offset: Offset(0, 0),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: width * 0.03),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
