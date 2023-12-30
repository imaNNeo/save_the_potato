class HighScoreBundle {
  final int version;
  final int highScore;
  final int timeStamp;

  HighScoreBundle({
    required this.version,
    required this.highScore,
    required this.timeStamp,
  });

  String serialize() => '$version:$highScore:$timeStamp';

  static HighScoreBundle deserialize(String bundleText) {
    final bundle = bundleText.split(":");
    return HighScoreBundle(
      version: int.parse(bundle[0]),
      highScore: int.parse(bundle[1]),
      timeStamp: int.parse(bundle[2]),
    );
  }
}
