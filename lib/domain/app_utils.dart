
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
}
