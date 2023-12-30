import 'package:firebase_auth/firebase_auth.dart';

class UserEntity {
  final User _firebaseUser;

  UserEntity(this._firebaseUser);

  bool get isAnonymous => _firebaseUser.isAnonymous;

  String get uid => _firebaseUser.uid;

  String get displayName => _firebaseUser.displayName ?? '';

  String get email => _firebaseUser.email ?? '';

  String get photoUrl => _firebaseUser.photoURL ?? '';

  String get providerId => _firebaseUser.providerData.first.providerId;

  String get providerDisplayName =>
      _firebaseUser.providerData.first.displayName ?? '';
}
