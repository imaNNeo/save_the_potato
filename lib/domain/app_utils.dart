import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/models/game_config_entity.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/widgets/new_rank_celebration_shareable_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUtils {
  static String getHighScoreRepresentation(int highScoreMilliseconds) {
    final minutes = highScoreMilliseconds ~/ 60000;
    final seconds = (highScoreMilliseconds % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static void tryToLaunchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  static String formatVersionName(String versionName) => 'v$versionName';

  static Future<void> shareScore({
    required OnlineScoreEntity score,
    required GameConfigEntity gameConfig,
  }) async {
    try {
      final bytes = await ScreenshotController().captureFromWidget(
        SizedBox(
          width: 400,
          child: NewRankCelebrationShareableWidget(
            scoreEntity: score,
          ),
        ),
      );
      final imageFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
      );

      final scoreStr = AppUtils.getHighScoreRepresentation(score.score);
      final shareTextWithRank = gameConfig.shareTextWithRank
          .replaceAll('{{score}}', scoreStr)
          .replaceAll('{{rank}}', score.rank.toString());

      final shareTextWithoutRank =
          gameConfig.shareTextWithoutRank.replaceAll('{{score}}', scoreStr);

      final shareText = score.rank <= gameConfig.shareTextWithRankThreshold
          ? shareTextWithRank
          : shareTextWithoutRank;
      await Share.shareXFiles(
        [imageFile],
        subject: '🏆 New High Score on Save The Potato!',
        text: shareText,
      );
    } catch (e) {
      debugPrint(e.toString());
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      rethrow;
    }
  }
}
