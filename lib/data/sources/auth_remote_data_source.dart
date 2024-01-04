import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
    final email = credential.user!.email ?? 'email was empty';
    await Clipboard.setData(ClipboardData(text: email));
    final idToken = (await credential.user!.getIdToken())!;
    return _functions.registerUser(idToken);
  }

  Future<UserEntity> registerAnonymously() => _functions.registerAnonymousUser();
}
