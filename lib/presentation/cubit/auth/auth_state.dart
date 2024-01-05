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
  });

  final UserEntity? user;
  final bool updateUserLoading;
  final PresentationMessage updateUserError;
  final PresentationMessage updateUserSucceeds;
  final bool authLoading;
  final PresentationMessage authError;
  final PresentationMessage authSucceeds;

  bool get isAnonymous => user == null || user!.type == UserType.anonymous;

  AuthState copyWith({
    ValueWrapper<UserEntity>? user,
    bool? updateUserLoading,
    PresentationMessage? updateUserError,
    PresentationMessage? updateUserSucceeds,
    bool? authLoading,
    PresentationMessage? authError,
    PresentationMessage? authSucceeds,
  }) {
    return AuthState(
      user: user != null ? user.value : this.user,
      updateUserLoading: updateUserLoading ?? this.updateUserLoading,
      updateUserError: updateUserError ?? this.updateUserError,
      updateUserSucceeds: updateUserSucceeds ?? this.updateUserSucceeds,
      authLoading: authLoading ?? this.authLoading,
      authError: authError ?? this.authError,
      authSucceeds: authSucceeds ?? this.authSucceeds,
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
      ];
}
