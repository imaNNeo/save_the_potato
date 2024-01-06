import 'dart:async';

import 'package:save_the_potato/data/key_value_storage.dart';

class ScoresLocalDataSource {
  final KeyValueStorage _keyValueStorage;

  ScoresLocalDataSource(this._keyValueStorage);

  final StreamController<int> _highScoreStreamController =
      StreamController<int>.broadcast();

  Stream<int> getHighScoreStream() => _highScoreStreamController.stream;

  Future<int?> getHighScore() => _keyValueStorage.getInt('high_score');

  Future<int> setHighScore(int highScoreMilliseconds) async {
    _highScoreStreamController.sink.add(highScoreMilliseconds);
    await _keyValueStorage.setInt(
      'high_score',
      highScoreMilliseconds,
    );
    return highScoreMilliseconds;
  }

  Future<void> clearHighScore() async {
    await setHighScore(0);
  }
}
