import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/data/sources/auth_data_source.dart';
import 'package:save_the_potato/data/sources/settings_data_source.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';

import 'domain/repository/auth_repository.dart';
import 'presentation/helpers/audio_helper.dart';

Future<void> setupServiceLocator() async {
  // Helpers
  getIt.registerLazySingleton<AudioHelper>(() => AudioHelper());
  getIt.registerLazySingleton<KeyValueStorage>(() {
    if (Platform.isIOS || Platform.isAndroid) {
      return SecureKeyValueStorage();
    } else {
      return SharedPrefKeyValueStorage();
    }
  });

  // Data sources
  getIt.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSource(getIt.get<KeyValueStorage>()),
  );
  getIt.registerLazySingleton<AuthDataSource>(
    () => AuthDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt.get<SettingsDataSource>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt.get<AuthDataSource>()),
  );
}

final getIt = GetIt.instance;
