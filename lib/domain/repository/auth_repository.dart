import 'package:save_the_potato/data/sources/auth_data_source.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepository(this._authDataSource);

  Future<void> anonymousLogin() async {
    if (_authDataSource.isSignedIn()) {
      return;
    }
    await _authDataSource.anonymousSignIn();
  }

  UserEntity? getCurrentUser() => _authDataSource.getCurrentUser();

  bool isSignedIn() => _authDataSource.isSignedIn();
}
