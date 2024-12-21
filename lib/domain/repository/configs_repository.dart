import 'package:save_the_potato/data/sources/local/configs_local_data_source.dart';

class ConfigsRepository {
  ConfigsRepository(
    this._configsLocalDataSource,
  );

  final ConfigsLocalDataSource _configsLocalDataSource;

  /// Whether the user has received the first health point,
  /// We use this to increase the chance of health generation to help the user
  /// learn about the game mechanics
  Future<void> setFirstHealthReceived(bool received) =>
      _configsLocalDataSource.setFirstHealthReceived(received);

  Future<bool> isFirstHealthReceived() =>
      _configsLocalDataSource.isFirstHealthReceived();
}
