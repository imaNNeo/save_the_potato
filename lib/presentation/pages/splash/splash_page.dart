import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/cubit/splash/splash_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/pages/fade_route.dart';
import 'package:save_the_potato/presentation/pages/main/main_page.dart';
import 'package:save_the_potato/presentation/widgets/potato_initialize.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool isUpdateDialogShowing = false;
  bool shouldOpenNextPage = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    final splashCubit = context.read<SplashCubit>();
    final scoresCubit = context.read<ScoresCubit>();
    splashCubit.pageOpen();
    scoresCubit.initialize();
  }

  void _openHomePage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      FadeRoute(page: const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashCubit, SplashState>(
      listener: (context, state) async {
        if (state.openNextPage) {
          if (isUpdateDialogShowing) {
            shouldOpenNextPage = true;
          } else {
            if (!context.mounted) {
              return;
            }
            _openHomePage(context);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: GameColors.splashColor,
          body: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Save the Potato',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  const SplashPotato(size: 180),
                  Expanded(child: Container()),
                ].animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                    ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Powered by',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Roboto'),
                    ),
                    Image.asset(
                      'assets/images/flutter_flame/flame-logo.png',
                      width: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.showingVersion,
                      style: const TextStyle(
                        color: GameColors.versionColor,
                        fontSize: 12,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                    const SizedBox(height: 14)
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
