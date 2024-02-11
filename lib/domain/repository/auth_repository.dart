import 'package:save_the_potato/data/sources/local/auth_local_data_source.dart';
import 'package:save_the_potato/data/sources/remote/auth_remote_data_source.dart';
import 'package:save_the_potato/data/sources/local/scores_local_data_source.dart';
import 'package:save_the_potato/data/sources/remote/scores_remote_data_source.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

typedef _AuthFunction = Future<UserEntity> Function(bool forceToReplace);

class AuthRepository {
  final AuthLocalDataSource _authLocalDataSource;
  final AuthRemoteDataSource _authRemoteDataSource;
  final ScoresLocalDataSource _scoresLocalDataSource;
  final ScoresRemoteDataSource _scoresRemoteDataSource;

  AuthRepository(
    this._authLocalDataSource,
    this._authRemoteDataSource,
    this._scoresLocalDataSource,
    this._scoresRemoteDataSource,
  );

  Stream<UserEntity?> getUserStream() => _authLocalDataSource.getUserStream();

  Future<UserEntity> getCurrentUser() async {
    await _authRemoteDataSource.reloadUser();
    final currentUser = await _authLocalDataSource.getUser();
    if (currentUser != null) {
      return currentUser;
    }
    return _authRemoteDataSource.tryToRegisterAnonymously();
  }

  Future<bool> isUserAnonymous() async {
    final currentUser = await getCurrentUser();
    return currentUser.type == UserType.anonymous ||
        _authRemoteDataSource.isUserAnonymous();
  }

  Future<bool> isSignedIn() => _authLocalDataSource.isSignedIn();

  Future<UserEntity> signInWithGoogle(bool forceToReplace) =>
      _signInSharedLogic(
        _authRemoteDataSource.signInWithGoogle,
        forceToReplace,
      );

  Future<UserEntity> signInWithApple(bool forceToReplace) => _signInSharedLogic(
        _authRemoteDataSource.signInWithApple,
        forceToReplace,
      );

  Future<UserEntity> _signInSharedLogic(
    _AuthFunction authFunction,
    bool forceToReplace,
  ) async {
    final user = await authFunction(forceToReplace);
    if (forceToReplace) {
      await _scoresLocalDataSource.clearHighScore();
      final scoreEntity = await _scoresRemoteDataSource.getScore();
      if (scoreEntity != null) {
        await _scoresLocalDataSource.setHighScore(scoreEntity);
      }
    }
    await _authLocalDataSource.saveUser(user);
    return user;
  }

  Future<UserEntity> updateUserNickname(String nickname) async {
    final user = await _authRemoteDataSource.updateUserNickname(nickname);
    await _authLocalDataSource.saveUser(user);
    return user;
  }
}
