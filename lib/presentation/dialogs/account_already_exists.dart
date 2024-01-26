import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:toastification/toastification.dart';

class AccountAlreadyExistsDialogContent extends StatelessWidget {
  const AccountAlreadyExistsDialogContent({
    super.key,
    required this.error,
  }) : super();

  final AccountAlreadyExistsError error;

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
                'An account with this email already exists. If you continue with the new account, your current data (such as high-score) will be lost and replaced with the new one.',
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (Platform.isIOS) {
                      context
                          .read<AuthCubit>()
                          .loginWithApple(forceToReplace: true);
                    } else {
                      context
                          .read<AuthCubit>()
                          .loginWithGoogle(forceToReplace: true);
                    }
                  },
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
                      : const Text(
                          'Continue',
                          style: TextStyle(
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
