import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authRepository,
  ) : super(const AuthState()) {
    initialize();
  }

  final AuthRepository _authRepository;

  void initialize() async {
    await _authRepository.anonymousLogin();
  }

  void login() async {
    if (Platform.isAndroid) {
      await _authRepository.signInWithGoogle();
    } else if (Platform.isIOS) {
      await _authRepository.signInWithApple();
    } else {
      throw Exception('Unsupported platform');
    }
  }
}
