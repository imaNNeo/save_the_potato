import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:save_the_potato/domain/extensions/string_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStorage {
  Future<bool?> getBool(String key);

  Future<void> setBool(String key, bool value);

  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<double?> getDouble(String key);

  Future<void> setDouble(String key, double value);

  Future<int?> getInt(String key);

  Future<void> setInt(String key, int value);
}

class SecureKeyValueStorage extends KeyValueStorage {
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<bool> getBool(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) {
      return Future.value(false);
    }
    return value.asBool;
  }

  @override
  Future<double?> getDouble(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) {
      return null;
    }
    return value.asDouble;
  }

  @override
  Future<int?> getInt(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) {
      return null;
    }
    return value.asInt;
  }

  @override
  Future<String?> getString(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) {
      return null;
    }
    return value;
  }

  @override
  Future<void> setBool(String key, bool value) =>
      _secureStorage.write(key: key, value: value.toString());

  @override
  Future<void> setDouble(String key, double value) =>
      _secureStorage.write(key: key, value: value.toString());

  @override
  Future<void> setInt(String key, int value) =>
      _secureStorage.write(key: key, value: value.toString());

  @override
  Future<void> setString(String key, String value) =>
      _secureStorage.write(key: key, value: value);
}

class SharedPrefKeyValueStorage extends KeyValueStorage {
  @override
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  @override
  Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  @override
  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}