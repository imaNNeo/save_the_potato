import 'package:get_it/get_it.dart';
import 'package:save_the_potato/data/sources/local/configs_local_data_source.dart';
import 'package:save_the_potato/data/sources/local/settings_data_source.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';

import 'data/sources/local/scores_local_data_source.dart';
import 'domain/repository/scores_repository.dart';
import 'presentation/helpers/audio_helper.dart';

Future<void> setupServiceLocator() async {
  // Helpers
  getIt.registerLazySingleton<AudioHelper>(() => AudioHelper());

  // Data sources
  getIt.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSource(),
  );
  getIt.registerLazySingleton<ScoresLocalDataSource>(
    () => ScoresLocalDataSource(),
  );
  getIt.registerLazySingleton<ConfigsLocalDataSource>(
    () => ConfigsLocalDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt.get<SettingsDataSource>()),
  );
  getIt.registerLazySingleton<ScoresRepository>(
    () => ScoresRepository(
      getIt.get<ScoresLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ConfigsRepository>(
    () => ConfigsRepository(
      getIt.get<ConfigsLocalDataSource>(),
    ),
  );
}

final getIt = GetIt.instance;
