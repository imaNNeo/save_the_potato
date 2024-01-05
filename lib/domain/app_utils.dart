
class AppUtils {
  static String getHighScoreRepresentation(int highScoreMilliseconds) {
    final minutes = highScoreMilliseconds ~/ 60000;
    final seconds = (highScoreMilliseconds % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
