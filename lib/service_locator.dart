import 'package:get_it/get_it.dart';
import 'package:save_the_potato/data/sources/settings_data_source.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';

import 'presentation/helpers/audio_helper.dart';

Future<void> setupServiceLocator() async {
  // Helpers
  getIt.registerLazySingleton<AudioHelper>(() => AudioHelper());

  // Data sources
  getIt.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt.get<SettingsDataSource>()),
  );
}

final getIt = GetIt.instance;
