import 'dart:async';

import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/domain/models/high_score_bundle.dart';

class ScoresLocalDataSource {
  final KeyValueStorage _keyValueStorage;

  ScoresLocalDataSource(this._keyValueStorage);

  final StreamController<HighScoreBundleEntity> _highScoreStreamController =
      StreamController<HighScoreBundleEntity>.broadcast();

  Stream<HighScoreBundleEntity> getHighScoreStream() =>
      _highScoreStreamController.stream;

  Future<HighScoreBundleEntity?> getHighScore() async {
    final String? highScoreStr = await _keyValueStorage.getString('high_score');
    try {
      return HighScoreBundleEntity.deserialize(highScoreStr!);
    } catch (e) {
      return null;
    }
  }

  Future<HighScoreBundleEntity> setHighScore(int highScoreMilliseconds) async {
    final bundle = HighScoreBundleEntity(
      version: 1,
      highScore: highScoreMilliseconds,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    );
    _highScoreStreamController.sink.add(bundle);
    await _keyValueStorage.setString(
      'high_score',
      bundle.serialize(),
    );
    return bundle;
  }

  Future<void> clearHighScore() async {
    await setHighScore(0);
  }
}
