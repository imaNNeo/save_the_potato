part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
  });

  final UserEntity? user;

  bool get isAnonymous => user == null || user!.type == UserType.anonymous;

  AuthState copyWith({
    ValueWrapper<UserEntity>? user,
  }) {
    return AuthState(
      user: user != null ? user.value : this.user,
    );
  }

  @override
  List<Object?> get props => [user];
}
