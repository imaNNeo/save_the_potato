import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/data/sources/auth_local_data_source.dart';
import 'package:save_the_potato/data/sources/auth_remote_data_source.dart';
import 'package:save_the_potato/data/sources/firebase_functions_wrapper.dart';
import 'package:save_the_potato/data/sources/settings_data_source.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';

import 'data/sources/scores_local_data_source.dart';
import 'domain/repository/auth_repository.dart';
import 'domain/repository/scores_repository.dart';
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
  getIt.registerLazySingleton<FirebaseFunctionsWrapper>(
    () => FirebaseFunctionsWrapper(
      getIt.get<KeyValueStorage>(),
    ),
  );

  // Data sources
  getIt.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSource(getIt.get<KeyValueStorage>()),
  );
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(
      getIt.get<KeyValueStorage>(),
    ),
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(
      getIt.get<FirebaseFunctionsWrapper>(),
    ),
  );
  getIt.registerLazySingleton<ScoresLocalDataSource>(
    () => ScoresLocalDataSource(
      getIt.get<KeyValueStorage>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt.get<SettingsDataSource>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      getIt.get<AuthLocalDataSource>(),
      getIt.get<AuthRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ScoresRepository>(
    () => ScoresRepository(getIt.get<ScoresLocalDataSource>()),
  );
}

final getIt = GetIt.instance;
