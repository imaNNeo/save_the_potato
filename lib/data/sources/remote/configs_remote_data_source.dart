import 'package:save_the_potato/data/sources/firebase_functions_wrapper.dart';
import 'package:save_the_potato/domain/models/game_config_entity.dart';

class ConfigsRemoteDataSource {
  final FirebaseFunctionsWrapper _functions;

  ConfigsRemoteDataSource(this._functions);

  Future<GameConfigEntity> getGameConfig() => _functions.getGameConfig();
}
