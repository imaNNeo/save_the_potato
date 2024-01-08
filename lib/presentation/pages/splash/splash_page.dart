import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/configs/configs_cubit.dart';
import 'package:save_the_potato/presentation/cubit/splash/splash_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/pages/main/main_page.dart';
import 'package:save_the_potato/presentation/widgets/potato_idle.dart';

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
    context.read<SplashCubit>().pageOpen();
    super.initState();
  }

  void _openHomePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashCubit, SplashState>(
      listener: (context, state) async {
        if (state.versionIsAllowed) {
          context.read<ConfigsCubit>().initialize();
          context.read<AuthCubit>().initialize();
        }

        if (state.showUpdatePopup != null) {
          isUpdateDialogShowing = true;
          await BaseDialog.showUpdateDialog(
            context,
            state.showUpdatePopup!,
          );
          if (!mounted) {
            return;
          }
          isUpdateDialogShowing = false;
          if (shouldOpenNextPage) {
            await await Future.delayed(Duration(milliseconds: 300));
            if (!mounted) {
              return;
            }
            _openHomePage(context);
          }
        }
        if (state.openNextPage) {
          if (isUpdateDialogShowing) {
            shouldOpenNextPage = true;
          } else {
            _openHomePage(context);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const PotatoIdle(
                      size: 180,
                    ),
                  ].animate().fadeIn(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                      ),
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
                    const Text(
                      'v1.0.0',
                      style: TextStyle(
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
