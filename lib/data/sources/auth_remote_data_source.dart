import 'package:firebase_auth/firebase_auth.dart';
import 'package:save_the_potato/data/sources/firebase_functions_wrapper.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class AuthRemoteDataSource {
  final FirebaseFunctionsWrapper _functions;

  AuthRemoteDataSource(this._functions);

  Future<UserEntity> anonymousSignIn() async {
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    final idToken = (await userCredential.user!.getIdToken())!;
    final user = await _functions.registerAnonymousUser(
      idToken,
    );
    return user;
  }

  Future<UserEntity> signInWithGoogle() =>
      _signInOrLinkWithProvider(GoogleAuthProvider());

  Future<UserEntity> signInWithApple() =>
      _signInOrLinkWithProvider(AppleAuthProvider());

  Future<UserEntity> _signInOrLinkWithProvider(AuthProvider provider) async {
    final currentAnonymousUser = FirebaseAuth.instance.currentUser;
    UserCredential credential;
    if (currentAnonymousUser != null) {
      credential = await currentAnonymousUser.linkWithProvider(provider);
    } else {
      credential = await FirebaseAuth.instance.signInWithProvider(provider);
    }
    // TODO: 12/31/23 We have to store it somewhere
    // print(credential.credential);
    // return UserEntity(credential.user!);
    return AnonymousUserEntity(uid: 'asdf', nickname: 'adsf');
  }
}
