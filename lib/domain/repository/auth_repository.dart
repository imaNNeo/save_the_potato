import 'package:save_the_potato/data/sources/auth_local_data_source.dart';
import 'package:save_the_potato/data/sources/auth_remote_data_source.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class AuthRepository {
  final AuthLocalDataSource _authLocalDataSource;
  final AuthRemoteDataSource _authRemoteDataSource;

  AuthRepository(this._authLocalDataSource, this._authRemoteDataSource);

  Stream<UserEntity?> getUserStream() =>
      _authLocalDataSource.getUserStream();
      
  Future<UserEntity> getCurrentUser() async {
    await _authRemoteDataSource.reloadUser();
    final currentUser = await _authLocalDataSource.getUser();
    if (currentUser != null) {
      return currentUser;
    }
    return _authRemoteDataSource.tryToRegisterAnonymously();
  }

  Future<bool> isSignedIn() => _authLocalDataSource.isSignedIn();

  Future<UserEntity> signInWithGoogle() async {
    final user = await _authRemoteDataSource.signInWithGoogle();
    await _authLocalDataSource.saveUser(user);
    return user;
  }

  Future<UserEntity> signInWithApple() async {
    final user = await _authRemoteDataSource.signInWithApple();
    await _authLocalDataSource.saveUser(user);
    return user;
  }
}
