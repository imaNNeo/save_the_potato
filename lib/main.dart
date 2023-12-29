import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/service_locator.dart';
import 'presentation/cubit/game_cubit.dart';
import 'presentation/cubit/settings/settings_cubit.dart';
import 'presentation/pages/main_page.dart';

void main() {
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
          create: (context) => GameCubit(getIt.get<AudioHelper>()),
        ),
      ],
      child: MaterialApp(
        title: 'Save the Potato',
        theme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'Cookies',
              ),
        ),
        home: const MainPage(),
      ),
    );
  }
}
