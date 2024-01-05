part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.updateUserLoading = false,
    this.updateUserError = PresentationMessage.empty,
    this.updateUserSucceeds = PresentationMessage.empty,
  });

  final UserEntity? user;
  final bool updateUserLoading;
  final PresentationMessage updateUserError;
  final PresentationMessage updateUserSucceeds;

  bool get isAnonymous => user == null || user!.type == UserType.anonymous;

  AuthState copyWith({
    ValueWrapper<UserEntity>? user,
    bool? updateUserLoading,
    PresentationMessage? updateUserError,
    PresentationMessage? updateUserSucceeds,
  }) {
    return AuthState(
      user: user != null ? user.value : this.user,
      updateUserLoading: updateUserLoading ?? this.updateUserLoading,
      updateUserError: updateUserError ?? this.updateUserError,
      updateUserSucceeds: updateUserSucceeds ?? this.updateUserSucceeds,
    );
  }

  @override
  List<Object?> get props => [
        user,
        updateUserLoading,
        updateUserError,
        updateUserSucceeds,
      ];
}
