import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authRepository,
  ) : super(const AuthState()) {
    initialize();
  }

  final AuthRepository _authRepository;

  late StreamSubscription _userStreamSubscription;

  void initialize() async {
    try {
      final user = await _authRepository.getCurrentUser();
      emit(
        state.copyWith(
          user: ValueWrapper(user),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }

    _userStreamSubscription = _authRepository.getUserStream().listen((event) {
      emit(
        state.copyWith(
          user: ValueWrapper(event),
        ),
      );
    });
  }

  void login() async {
    try {
      if (Platform.isAndroid) {
        await _authRepository.signInWithGoogle();
      } else if (Platform.isIOS) {
        await _authRepository.signInWithApple();
      } else {
        throw Exception('Unsupported platform');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Future<void> close() {
    _userStreamSubscription.cancel();
    return super.close();
  }

  void updateNickname(String newNickname) async {
    if (newNickname == state.user?.nickname) {
      return;
    }
    emit(state.copyWith(updateUserLoading: true));
    try {
      final user = await _authRepository.updateUserNickname(
        newNickname,
      );
      emit(
        state.copyWith(
          user: ValueWrapper(user),
          updateUserLoading: false,
          updateUserSucceeds: 'Nickname updated',
        ),
      );
      emit(state.copyWith(updateUserSucceeds: ''));
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(
          updateUserLoading: false,
          updateUserError: 'Nickname update failed, please try again later!',
        ),
      );
      emit(state.copyWith(updateUserError: ''));
    }
  }
}
