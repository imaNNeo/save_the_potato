import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  static Future<void> shareScore(OnlineScoreEntity score) async {
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
    await Share.shareXFiles(
      [imageFile],
      subject: '🏆 New High Score on Save The Potato!',
      text:
          "Hey there! I just smashed my previous record and set a new high score of ${AppUtils.getHighScoreRepresentation(score.score)} on Save The Potato! 🎉 It was intense, and I'm climbing up the leaderboard. Think you can beat me? Give it a shot and let's see who's the true Potato Protector! 🥔🛡️ #SaveThePotato #HighScoreChallenge",
    );
  }
}
