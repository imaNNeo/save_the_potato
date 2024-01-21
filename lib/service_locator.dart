import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:save_the_potato/data/firebase_analytics_helper.dart';
import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/data/sources/auth_local_data_source.dart';
import 'package:save_the_potato/data/sources/auth_remote_data_source.dart';
import 'package:save_the_potato/data/sources/configs_local_data_source.dart';
import 'package:save_the_potato/data/sources/configs_remote_data_source.dart';
import 'package:save_the_potato/data/sources/firebase_functions_wrapper.dart';
import 'package:save_the_potato/data/sources/scores_remote_data_source.dart';
import 'package:save_the_potato/data/sources/settings_data_source.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
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
  getIt.registerLazySingleton<AnalyticsHelper>(
    () => FirebaseAnalyticsHelper(),
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
  getIt.registerLazySingleton<ScoresRemoteDataSource>(
    () => ScoresRemoteDataSource(
      getIt.get<FirebaseFunctionsWrapper>(),
    ),
  );
  getIt.registerLazySingleton<ConfigsLocalDataSource>(
    () => ConfigsLocalDataSource(
      getIt.get<KeyValueStorage>(),
    ),
  );
  getIt.registerLazySingleton<ConfigsRemoteDataSource>(
    () => ConfigsRemoteDataSource(
      getIt.get<FirebaseFunctionsWrapper>(),
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
      getIt.get<ScoresLocalDataSource>(),
      getIt.get<ScoresRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ScoresRepository>(
    () => ScoresRepository(
      getIt.get<ScoresLocalDataSource>(),
      getIt.get<ScoresRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ConfigsRepository>(
    () => ConfigsRepository(
      getIt.get<ConfigsLocalDataSource>(),
      getIt.get<ConfigsRemoteDataSource>(),
      getIt.get<AuthLocalDataSource>(),
    ),
  );
}

final getIt = GetIt.instance;
