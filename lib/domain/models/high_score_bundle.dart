class HighScoreBundleEntity {
  final int version;
  final int highScore;
  final int timeStamp;

  HighScoreBundleEntity({
    required this.version,
    required this.highScore,
    required this.timeStamp,
  });

  String serialize() => '$version:$highScore:$timeStamp';

  String get representation {
    final minutes = highScore ~/ 60000;
    final seconds = (highScore % 60000) ~/ 1000;
    return '$minutes:$seconds';
  }

  static HighScoreBundleEntity deserialize(String bundleText) {
    final bundle = bundleText.split(":");
    return HighScoreBundleEntity(
      version: int.parse(bundle[0]),
      highScore: int.parse(bundle[1]),
      timeStamp: int.parse(bundle[2]),
    );
  }
}
