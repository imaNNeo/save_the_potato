import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/presentation_message.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/auth_repository.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';

part 'auth_state.dart';

typedef _AuthFunction = Future<UserEntity> Function(bool forceToReplace);

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authRepository,
    this._configsRepository,
  ) : super(const AuthState());

  final AuthRepository _authRepository;
  final ConfigsRepository _configsRepository;
  final AnalyticsHelper _analyticsHelper;

  late StreamSubscription _userStreamSubscription;

  void initialize() async {
    try {
      final user = await _authRepository.getCurrentUser();
      FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
      emit(
        state.copyWith(
          user: ValueWrapper(user),
        ),
      );
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      debugPrint('auth error: ${e.toString()}');
    }

    _userStreamSubscription = _authRepository.getUserStream().listen((user) {
      if (user != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
      }
      emit(
        state.copyWith(
          user: ValueWrapper(user),
        ),
      );
    });
  }

  void loginWithApple({
    bool forceToReplace = false,
  }) {
    _analyticsHelper.logLogin(loginMethod: 'apple');
    _sharedLoginLogic(
        _authRepository.signInWithApple,
        forceToReplace,
      );
  };

  void loginWithGoogle({
    bool forceToReplace = false,
  }) {
    _analyticsHelper.logLogin(loginMethod: 'apple');
    _sharedLoginLogic(
        _authRepository.signInWithGoogle,
        forceToReplace,
      );
  }

  void _sharedLoginLogic(_AuthFunction loginFunction, bool forceToReplace) async {
    emit(state.copyWith(authLoading: true));
    try {
      final user = await loginFunction(forceToReplace);
      emit(state.copyWith(
        authLoading: false,
        user: ValueWrapper(user),
        authSucceeds: PresentationMessage.raw('Successfully logged in'),
      ));
      emit(state.copyWith(
        authSucceeds: PresentationMessage.empty,
      ));
    } catch (e) {
      if (e is AccountAlreadyExistsError) {
        emit(state.copyWith(
          authLoading: false,
          accountAlreadyExistsError: ValueWrapper(e),
        ));
        emit(state.copyWith(
          accountAlreadyExistsError: const ValueWrapper(null),
        ));
        return;
      }
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
    if (newNickname.length < config.nicknameMinLength) {
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
      debugPrint('auth error 2: ${e.toString()}');
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
