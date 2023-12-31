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

  Future<UserEntity> signInWithGoogle() async {
    final userCredential = await FirebaseAuth.instance.signInWithProvider(
      GoogleAuthProvider(),
    );
    return UserEntity(userCredential.user!);
  }

  Future<UserEntity> signInWithApple() async {
    final userCredential = await FirebaseAuth.instance.signInWithProvider(
      AppleAuthProvider(),
    );
    return UserEntity(userCredential.user!);
  }
}
