import 'package:flutter/foundation.dart';
import 'package:save_the_potato/data/sources/local/auth_local_data_source.dart';
import 'package:save_the_potato/data/sources/local/configs_local_data_source.dart';
import 'package:save_the_potato/data/sources/remote/configs_remote_data_source.dart';
import 'package:save_the_potato/domain/models/game_config_entity.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class ConfigsRepository {
  ConfigsRepository(
    this._configsLocalDataSource,
    this._configsRemoteDataSource,
    this._authLocalDataSource,
  );

  final ConfigsLocalDataSource _configsLocalDataSource;
  final ConfigsRemoteDataSource _configsRemoteDataSource;
  final AuthLocalDataSource _authLocalDataSource;

  Future<GameConfigEntity> getGameConfig() => _configsLocalDataSource.getGameConfig();
  
  Stream<GameConfigEntity> getGameConfigStream() async* {
    final localConfigs = await _configsLocalDataSource.getGameConfig();
    yield localConfigs;

    GameConfigEntity? remoteConfigs;
    try {
      remoteConfigs = await _configsRemoteDataSource.getGameConfig();
    } catch (e, stackTrace) {
      debugPrint('configs error: ${e.toString()}, \n$stackTrace');
    }

    if (remoteConfigs != null && localConfigs != remoteConfigs) {
      await _configsLocalDataSource.setGameConfig(remoteConfigs);
      yield remoteConfigs;
    }

    UserEntity? lastUser = await _authLocalDataSource.getUser();
    await for (final user in _authLocalDataSource.getUserStream()) {
      if (lastUser?.type != user?.type) {
        try {
          remoteConfigs = null;
          remoteConfigs = await _configsRemoteDataSource.getGameConfig();
        } catch (e) {
          debugPrint(e.toString());
        }
        if (remoteConfigs != null && localConfigs != remoteConfigs) {
          await _configsLocalDataSource.setGameConfig(remoteConfigs);
          yield remoteConfigs;
        }
      }
      lastUser = user;
    }
  }

  /// Whether the user has received the first health point,
  /// We use this to increase the chance of health generation to help the user
  /// learn about the game mechanics
  Future<void> setFirstHealthReceived(bool received) =>
      _configsLocalDataSource.setFirstHealthReceived(received);

  Future<bool> isFirstHealthReceived() =>
      _configsLocalDataSource.isFirstHealthReceived();
}
