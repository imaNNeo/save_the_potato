import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_poki_sdk/flutter_poki_sdk.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/pages/splash/splash_page.dart';
import 'package:save_the_potato/service_locator.dart';
import 'presentation/cubit/game/game_cubit.dart';
import 'presentation/cubit/scores/scores_cubit.dart';
import 'presentation/cubit/settings/settings_cubit.dart';
import 'presentation/cubit/splash/splash_cubit.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  try {
    await getIt.get<AudioHelper>().initialize();
    if (kIsWeb || kIsWasm) {
      try {
        await PokiSDK.init();
      } catch (e, stack) {
        debugPrintStack(stackTrace: stack);
      }
    }
  } catch (e) {
    debugPrint('Error initializing: $e');
  }
  runApp(const MyApp());
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
            getIt.get<ConfigsRepository>(),
          ),
        ),
        BlocProvider<ScoresCubit>(
          create: (context) => ScoresCubit(
            getIt.get<ScoresRepository>(),
          ),
        ),
        BlocProvider<SplashCubit>(
          create: (context) => SplashCubit(),
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
              letterSpacing: 8,
              fontFamily: 'Cookies',
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
        ),
        home: const SplashPage(),
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
