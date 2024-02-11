import 'dart:convert';

import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/domain/models/game_config_entity.dart';

class ConfigsLocalDataSource {
  static const String _gameConfigKey = 'gameConfig';

  ConfigsLocalDataSource(this._keyValueStorage);

  final KeyValueStorage _keyValueStorage;

  Future<GameConfigEntity> getGameConfig() async {
    try {
      final gameConfigJson = await _keyValueStorage.getString(
        _gameConfigKey,
      );
      return GameConfigEntity.fromJson(jsonDecode(gameConfigJson!));
    } catch (e) {
      return GameConfigEntity.initialOfflineConfigs;
    }
  }

  Future<void> setGameConfig(GameConfigEntity gameConfig) async {
    await _keyValueStorage.setString(
      _gameConfigKey,
      jsonEncode(gameConfig.toJson()),
    );
  }

  Future<bool> isFirstHealthReceived() async {
    return (await _keyValueStorage.getBool('first_health_received')) ?? false;
  }

  Future<void> setFirstHealthReceived(bool received) async {
    await _keyValueStorage.setBool('first_health_received', received);
  }
}
