import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/presentation_message.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/auth_repository.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';

part 'auth_state.dart';

typedef _AuthFunction = Future<UserEntity> Function();

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authRepository,
    this._configsRepository,
  ) : super(const AuthState()) {
    initialize();
  }

  final AuthRepository _authRepository;
  final ConfigsRepository _configsRepository;

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

  void loginWithApple() => _sharedLoginLogic(
        _authRepository.signInWithApple,
      );

  void loginWithGoogle() => _sharedLoginLogic(
        _authRepository.signInWithGoogle,
      );

  void _sharedLoginLogic(_AuthFunction loginFunction) async {
    emit(state.copyWith(authLoading: true));
    try {
      final user = await loginFunction();
      emit(state.copyWith(
        authLoading: false,
        user: ValueWrapper(user),
        authSucceeds: PresentationMessage.raw('Successfully logged in'),
      ));
      emit(state.copyWith(
        authSucceeds: PresentationMessage.empty,
      ));
    } catch (e) {
      emit(state.copyWith(
        authLoading: false,
        authError: PresentationMessage.fromError(e),
      ));
      emit(state.copyWith(
        authError: PresentationMessage.empty,
      ));
    }
  }

  void updateNickname(String newNickname) async {
    if (newNickname == state.user?.nickname) {
      return;
    }

    final config = await _configsRepository.getGameConfig();
    if (newNickname.length < config.nicknameMinLength ) {
      emit(state.copyWith(
        updateUserError: PresentationMessage.raw('Nickname is too short'),
      ));
      emit(state.copyWith(
        updateUserError: PresentationMessage.empty,
      ));
      return;
    }

    if (newNickname.length > config.nicknameMaxLength) {
      emit(state.copyWith(
        updateUserError: PresentationMessage.raw('Nickname is too long'),
      ));
      emit(state.copyWith(
        updateUserError: PresentationMessage.empty,
      ));
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
          updateUserSucceeds: PresentationMessage.raw('Nickname updated'),
        ),
      );
      emit(state.copyWith(
        updateUserSucceeds: PresentationMessage.empty,
      ));
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(
          updateUserLoading: false,
          updateUserError: PresentationMessage.fromError(e),
        ),
      );
      emit(state.copyWith(
        updateUserError: PresentationMessage.empty,
      ));
    }
  }

  @override
  Future<void> close() {
    _userStreamSubscription.cancel();
    return super.close();
  }
}
