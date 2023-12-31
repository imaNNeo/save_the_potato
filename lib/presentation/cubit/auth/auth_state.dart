part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.isAnonymous = true,
  });

  final bool isAnonymous;

  @override
  List<Object?> get props => [isAnonymous];
}
