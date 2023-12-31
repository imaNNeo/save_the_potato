import 'package:firebase_auth/firebase_auth.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class AuthDataSource {
  Future<UserEntity> anonymousSignIn() async {
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    return UserEntity(userCredential.user!);
  }

  UserEntity? getCurrentUser() => FirebaseAuth.instance.currentUser == null
      ? null
      : UserEntity(
          FirebaseAuth.instance.currentUser!,
        );

  bool isSignedIn() => getCurrentUser() != null;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
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
    print(credential.credential);
    return UserEntity(credential.user!);
  }
}
