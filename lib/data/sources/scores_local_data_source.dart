import 'dart:async';
import 'dart:convert';

import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';

class ScoresLocalDataSource {
  static const _highScoreKey = 'high_score';
  final KeyValueStorage _keyValueStorage;

  ScoresLocalDataSource(this._keyValueStorage);

  final StreamController<ScoreEntity> _highScoreStreamController =
      StreamController<ScoreEntity>.broadcast();

  Stream<ScoreEntity> getHighScoreStream() => _highScoreStreamController.stream;

  Future<ScoreEntity?> getHighScore() async {
    final scoreJsonStr = await _keyValueStorage.getString(_highScoreKey);
    if (scoreJsonStr == null || scoreJsonStr.isEmpty) {
      return null;
    }
    return ScoreEntity.fromJson(jsonDecode(scoreJsonStr!));
  }

  Future<ScoreEntity> setHighScore(ScoreEntity scoreEntity) async {
    _highScoreStreamController.sink.add(scoreEntity);
    await _keyValueStorage.setString(
      _highScoreKey,
      jsonEncode(scoreEntity.toJson()),
    );
    return scoreEntity;
  }

  Future<void> clearHighScore() async {
    await setHighScore(OfflineScoreEntity(score: 0));
  }
}
