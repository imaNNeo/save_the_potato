import 'package:flutter/material.dart';

class GameColors {
  static const leaderboardGoldenColor = Color(0xFFFFD700);
  static const leaderboardGoldenColorText = Color(0xFF1C1B1F);
  static const leaderboardSilverColor = Color(0xFFC0C0C0);
  static const leaderboardSilverColorText = Color(0xFF1C1B1F);
  static const leaderboardBronzeColor = Color(0xFFCD7F32);
  static const leaderboardBronzeColorText = Color(0xFF1C1B1F);
  static const leaderboardOtherColor = Color(0xFF4B4B4B);
  static const leaderboardOtherColorText = Color(0xFFFFFFFF);

  static const linkBlueColor = Colors.blue;
  static const gameBlue = Color(0xFF0063BE);

  static Color getRankBgColor(int rank) => switch (rank) {
        1 => GameColors.leaderboardGoldenColor,
        2 => GameColors.leaderboardSilverColor,
        3 => GameColors.leaderboardBronzeColor,
        _ => GameColors.leaderboardOtherColor,
      };

  static Color getRankTextColor(int rank) => switch (rank) {
        1 => GameColors.leaderboardGoldenColorText,
        2 => GameColors.leaderboardSilverColorText,
        3 => GameColors.leaderboardBronzeColorText,
        _ => GameColors.leaderboardOtherColorText,
      };

  static Color getLeaderboardStrokeColor(
    BuildContext context,
    isMine,
    int rank,
  ) {
    final mineBorderColor = rank <= 3
        ? GameColors.getRankBgColor(rank)
        : Theme.of(context).colorScheme.primary;
    final normalBorderColor = Theme.of(context).dividerColor.withOpacity(0.3);
    return isMine ? mineBorderColor : normalBorderColor;
  }

  static const Color versionColor = Color(0xB2FFFFFF);

  static const healthPointColor = Color(0xFFFF0058);
}
