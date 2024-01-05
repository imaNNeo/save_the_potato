import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:toastification/toastification.dart';

class AuthDialogContent extends StatelessWidget {
  const AuthDialogContent({super.key}) : super();

  String get _buttonText {
    if (Platform.isIOS) {
      return 'Sign in with Apple';
    }
    return 'Sign in with Google';
  }

  void _signInClicked(BuildContext context) {
    if (Platform.isIOS) {
      context.read<AuthCubit>().loginWithApple();
    } else {
      context.read<AuthCubit>().loginWithGoogle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (_, state) {
        if (state.authError.isNotEmpty) {
          state.authError.showAsToast(
            context,
            alignment: Alignment.topCenter,
            type: ToastificationType.warning,
          );
        }
        if (state.authSucceeds.isNotEmpty) {
          state.authSucceeds.showAsToast(
            context,
            type: ToastificationType.success,
          );
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "Sign in to:\n1. Be able to change your nickname\n2. Save your high score"),
              const SizedBox(height: 16.0),
              RichText(
                text: TextSpan(
                  text: 'By signing in you agree to our ',
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GameColors.linkBlueColor,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            AppUtils.tryToLaunchUrl(GameConstants.privacyPolicy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _signInClicked(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: state.authLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(),
                        )
                      : Text(
                          _buttonText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
