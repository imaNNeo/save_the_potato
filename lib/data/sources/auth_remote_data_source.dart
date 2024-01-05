import 'package:firebase_auth/firebase_auth.dart';
import 'package:save_the_potato/data/sources/firebase_functions_wrapper.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class AuthRemoteDataSource {
  final FirebaseFunctionsWrapper _functions;

  AuthRemoteDataSource(this._functions);

  Future<UserEntity> signInWithGoogle() => _signInOrLinkWithProvider(
        GoogleAuthProvider().addScope('email'),
      );

  Future<UserEntity> signInWithApple() => _signInOrLinkWithProvider(
        AppleAuthProvider().addScope('email'),
      );

  Future<UserEntity> _signInOrLinkWithProvider(AuthProvider provider) async {
    final currentAnonymousUser = FirebaseAuth.instance.currentUser;
    UserCredential credential;
    if (currentAnonymousUser != null && currentAnonymousUser.isAnonymous) {
      credential = await currentAnonymousUser.linkWithProvider(provider);
    } else {
      credential = await FirebaseAuth.instance.signInWithProvider(provider);
    }
    final idToken = (await credential.user!.getIdToken())!;
    return _functions.registerUser(idToken);
  }

  Future<UserEntity> tryToRegisterAnonymously() =>
      _functions.tryToRegisterAnonymousUser();

  Future<void> reloadUser() => FirebaseAuth.instance.currentUser!.reload();

  Future<UserEntity> updateUserNickname(String nickname) async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.updateDisplayName(nickname);
    await user.reload();
    return _functions.updateUserNickname(nickname);
  }

  bool isUserAnonymous() => FirebaseAuth.instance.currentUser!.isAnonymous;
}
