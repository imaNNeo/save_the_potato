import 'package:firebase_auth/firebase_auth.dart';
import 'package:save_the_potato/data/sources/firebase_functions_wrapper.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class AuthRemoteDataSource {
  final FirebaseFunctionsWrapper _functions;

  AuthRemoteDataSource(this._functions);

  Future<UserEntity> signInWithGoogle(bool forceToReplace) =>
      _signInOrLinkWithProvider(
        GoogleAuthProvider().addScope('email'),
        forceToReplace,
      );

  Future<UserEntity> signInWithApple(bool forceToReplace) =>
      _signInOrLinkWithProvider(
        AppleAuthProvider().addScope('email'),
        forceToReplace,
      );

  /// [forceToReplace] is used to replace the current anonymous user with the new one 
  /// without any link it means user agreed on that
  Future<UserEntity> _signInOrLinkWithProvider(
    AuthProvider provider,
    bool forceToReplace,
  ) async {
    final currentAnonymousUser = FirebaseAuth.instance.currentUser;
    UserCredential credential;
    if (currentAnonymousUser != null &&
        currentAnonymousUser.isAnonymous &&
        !forceToReplace) {
      try {
        credential = await currentAnonymousUser.linkWithProvider(provider);
      } catch (e) {
        if (e is FirebaseAuthException &&
            e.code == 'credential-already-in-use') {
          throw AccountAlreadyExistsError(email: e.email);
        } else {
          rethrow;
        }
      }
    } else {
      if (forceToReplace && currentAnonymousUser != null) {
        await currentAnonymousUser.delete();
      }
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
