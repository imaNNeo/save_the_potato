part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.updateUserLoading = false,
    this.updateUserError = '',
    this.updateUserSucceeds = '',
  });

  final UserEntity? user;
  final bool updateUserLoading;
  final String updateUserError;
  final String updateUserSucceeds;

  bool get isAnonymous => user == null || user!.type == UserType.anonymous;

  AuthState copyWith({
    ValueWrapper<UserEntity>? user,
    bool? updateUserLoading,
    String? updateUserError,
    String? updateUserSucceeds,
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
