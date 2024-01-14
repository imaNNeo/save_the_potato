import 'dart:async';

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

  Future<void> remove(String key);

  Stream<dynamic> watch(String key);
}

class SecureKeyValueStorage extends KeyValueStorage {
  final _secureStorage = const FlutterSecureStorage();

  final StreamController<(String key, dynamic data)> _controller =
      StreamController<(String key, dynamic data)>.broadcast();

  @override
  Future<bool?> getBool(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) {
      return null;
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
  Future<void> setBool(String key, bool value) async {
    await _secureStorage.write(key: key, value: value.toString());
    _controller.sink.add((key, value));
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _secureStorage.write(key: key, value: value.toString());
    _controller.sink.add((key, value));
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _secureStorage.write(key: key, value: value.toString());
    _controller.sink.add((key, value));
  }

  @override
  Future<void> setString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
    _controller.sink.add((key, value));
  }

  @override
  Future<void> remove(String key) async {
    await _secureStorage.delete(key: key);
    _controller.sink.add((key, null));
  }

  @override
  Stream<dynamic> watch(String key) => _controller.stream
      .where((event) => event.$1 == key)
      .map((event) => event.$2)
      .distinct();
}

class SharedPrefKeyValueStorage extends KeyValueStorage {
  final StreamController<(String key, dynamic data)> _controller =
      StreamController<(String key, dynamic data)>.broadcast();

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
    _controller.sink.add((key, value));
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
    _controller.sink.add((key, value));
  }

  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    _controller.sink.add((key, value));
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    _controller.sink.add((key, value));
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    _controller.sink.add((key, null));
  }

  @override
  Stream<dynamic> watch(String key) => _controller.stream
      .where((event) => event.$1 == key)
      .map((event) => event.$2)
      .distinct();
}
