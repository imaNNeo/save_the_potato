import 'dart:convert';

import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class AuthLocalDataSource {
  static const _userKey = 'user';

  final KeyValueStorage _storage;

  AuthLocalDataSource(this._storage);

  Future<void> saveUser(UserEntity user) async {
    await _storage.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserEntity?> getUser() async {
    try {
      final userJson = await _storage.getString(_userKey);
      final userMap = jsonDecode(userJson!) as Map<String, dynamic>;
      return UserEntity.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    final user = await getUser();
    return user != null && user.type != UserType.anonymous;
  }

  Future<void> signOut() async {
    await _storage.remove(_userKey);
  }
}
