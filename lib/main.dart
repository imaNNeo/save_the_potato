import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/service_locator.dart';
import 'domain/repository/auth_repository.dart';
import 'firebase_options.dart';
import 'presentation/cubit/game_cubit.dart';
import 'presentation/cubit/scores/scores_cubit.dart';
import 'presentation/cubit/settings/settings_cubit.dart';
import 'presentation/pages/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  setupServiceLocator();
  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (context) => SettingsCubit(
            getIt.get<SettingsRepository>(),
            getIt.get<AudioHelper>(),
          ),
        ),
        BlocProvider<GameCubit>(
          create: (context) => GameCubit(
            getIt.get<AudioHelper>(),
            getIt.get<ScoresRepository>(),
          ),
        ),
        BlocProvider<ScoresCubit>(
          create: (context) => ScoresCubit(
            getIt.get<ScoresRepository>(),
          ),
        ),
        BlocProvider<AuthCubit>(
          lazy: false,
          create: (context) => AuthCubit(
            getIt.get<AuthRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Save the Potato',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'Cookies',
              ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
        ),
        home: const MainPage(),
      ),
    );
  }
}
