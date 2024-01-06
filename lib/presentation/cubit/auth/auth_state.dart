part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.updateUserLoading = false,
    this.updateUserError = PresentationMessage.empty,
    this.updateUserSucceeds = PresentationMessage.empty,
    this.authLoading = false,
    this.authError = PresentationMessage.empty,
    this.authSucceeds = PresentationMessage.empty,
    this.accountAlreadyExistsError,
  });

  final UserEntity? user;
  final bool updateUserLoading;
  final PresentationMessage updateUserError;
  final PresentationMessage updateUserSucceeds;
  final bool authLoading;
  final PresentationMessage authError;
  final PresentationMessage authSucceeds;
  final AccountAlreadyExistsError? accountAlreadyExistsError;

  bool get isAnonymous => user == null || user!.type == UserType.anonymous;

  AuthState copyWith({
    ValueWrapper<UserEntity>? user,
    bool? updateUserLoading,
    PresentationMessage? updateUserError,
    PresentationMessage? updateUserSucceeds,
    bool? authLoading,
    PresentationMessage? authError,
    PresentationMessage? authSucceeds,
    ValueWrapper<AccountAlreadyExistsError>? accountAlreadyExistsError,
  }) {
    return AuthState(
      user: user != null ? user.value : this.user,
      updateUserLoading: updateUserLoading ?? this.updateUserLoading,
      updateUserError: updateUserError ?? this.updateUserError,
      updateUserSucceeds: updateUserSucceeds ?? this.updateUserSucceeds,
      authLoading: authLoading ?? this.authLoading,
      authError: authError ?? this.authError,
      authSucceeds: authSucceeds ?? this.authSucceeds,
      accountAlreadyExistsError: accountAlreadyExistsError != null
          ? accountAlreadyExistsError.value
          : this.accountAlreadyExistsError,
    );
  }

  @override
  List<Object?> get props => [
        user,
        updateUserLoading,
        updateUserError,
        updateUserSucceeds,
        authLoading,
        authError,
        authSucceeds,
        accountAlreadyExistsError,
      ];
}
