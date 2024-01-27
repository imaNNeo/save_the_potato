import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/domain/extensions/map_entries_list_extensions.dart';
import 'package:save_the_potato/domain/extensions/map_extensions.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/game_config_entity.dart';
import 'package:save_the_potato/domain/models/leaderboard_response_entity.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:uuid/uuid.dart';

class FirebaseFunctionsWrapper {
  final KeyValueStorage _storage;
  static const _region = 'us-central1';
  static const userKey = 'user';
  static const deviceIdKey = 'deviceId';

  FirebaseFunctionsWrapper(this._storage) {
    // if (kDebugMode) {
    //   /// Use the emulator for Cloud Functions if running locally
    //   FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    // }
  }

  // I need to synchronize this function (locking it) because there might be a situation where we have duplicate calls
  Completer<UserEntity>? _registerAnonymousUserCompleter;
  Future<UserEntity> tryToRegisterAnonymousUser() async {
    if (_registerAnonymousUserCompleter != null &&
        !_registerAnonymousUserCompleter!.isCompleted) {
      return _registerAnonymousUserCompleter!.future;
    }
    _registerAnonymousUserCompleter = Completer();
    _registerAnonymousUser()
        .then((user) => _registerAnonymousUserCompleter!.complete(user))
        .onError(
          (error, stackTrace) => _registerAnonymousUserCompleter!.completeError(
            error ?? StateError('Unknown error'),
            stackTrace,
          ),
        );
    return _registerAnonymousUserCompleter!.future;
  }

  Future<UserEntity> _registerAnonymousUser() async {
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    final idToken = (await userCredential.user!.getIdToken())!;
    final user = await registerUser(idToken);
    await _storage.setString(userKey, jsonEncode(user.toJson()));
    return user;
  }

  Completer<String>? _authTokenCompleter;
  Future<String> _getAuthToken() async {
    if (_authTokenCompleter != null && !_authTokenCompleter!.isCompleted) {
      return _authTokenCompleter!.future;
    }
    _authTokenCompleter = Completer();
    try {
      if (FirebaseAuth.instance.currentUser == null ||
          (await _storage.getString(userKey)) == null) {
        await tryToRegisterAnonymousUser();
      }
      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser!.getIdToken();
      } catch (e) {
        await tryToRegisterAnonymousUser();
        token = await FirebaseAuth.instance.currentUser!.getIdToken();
      }
      if (token == null) {
        await FirebaseAuth.instance.signOut();
        await _storage.remove(userKey);
        throw StateError('User token is null? why?');
      }
      _authTokenCompleter!.complete(token);
      return token;
    } catch (e) {
      _authTokenCompleter!.completeError(e);
      rethrow;
    }
  }

  Future<dynamic> _callFunction<T>({
    required String name,
    Map<String, dynamic>? parameters,
    bool returnFullResponse = false,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('-> firebase functions ($name):');
        if (parameters != null) {
          debugPrint('params: $parameters');
        }
      }
      parameters ??= <String, dynamic>{};

      const tokenKey = 'token';
      if (!parameters.containsKey(tokenKey)) {
        try {
          parameters['token'] = await _getAuthToken();
        } catch (e, stackTrace) {
          FirebaseCrashlytics.instance.recordError(e, stackTrace);
          debugPrint('Error getting auth token: $e');
        }
      }

      final response = await FirebaseFunctions.instanceFor(region: _region)
          .httpsCallable(name)
          .call(parameters.removeNullValues());
      final parsedResponse = _FirebaseFunctionsResponseParser.parseResponse(
        response.data,
      );
      if (kDebugMode) {
        debugPrint('<- firebase functions ($name):');
        debugPrint('$parsedResponse');
      }
      if (parsedResponse is! Map<String, dynamic>) {
        // Primitive types maybe?
        return parsedResponse;
      }
      return parsedResponse;
    } catch (e) {
      throw _mapToDomainError(e);
    }
  }

  Future<UserEntity> registerUser(String token) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    late String deviceInfoStr;
    if (Platform.isAndroid) {
      deviceInfoStr = jsonEncode((await deviceInfo.androidInfo).data);
    } else if (Platform.isIOS) {
      deviceInfoStr = jsonEncode((await deviceInfo.iosInfo).data);
    } else {
      deviceInfoStr = '';
    }
    final response = await _callFunction(
      name: 'registerUser',
      parameters: {
        'token': token,
        'deviceId': await getDeviceId(),
        'deviceInfo': deviceInfoStr,
      },
    );
    return UserEntity.fromJson(response['data']);
  }

  Future<String> getDeviceId() async {
    String? deviceId = await _storage.getString(deviceIdKey);
    if (deviceId != null) {
      return deviceId;
    }
    final newDeviceId = const Uuid().v4();
    await _storage.setString(deviceIdKey, newDeviceId);
    assert((await _storage.getString(deviceIdKey)) == newDeviceId);
    return newDeviceId;
  }

  Future<OnlineScoreEntity> submitScore(int score) async {
    final response = await _callFunction(
      name: 'submitScore',
      parameters: <String, dynamic>{
        'score': score,
      },
    );
    return OnlineScoreEntity.fromJson(response['data']);
  }

  Future<OnlineScoreEntity?> getScore() async {
    try {
      final response = await _callFunction(name: 'getScore');
      return OnlineScoreEntity.fromJson(response['data']);
    } catch (e) {
      return null;
    }
  }

  Future<LeaderboardResponseEntity> getLeaderboard(
    int pageLimit,
    String? pageLastId,
  ) async {
    final response = await _callFunction(
      name: 'getLeaderboard',
      parameters: {
        'page_limit': pageLimit,
        'page_last_id': pageLastId
      }
    );
    return LeaderboardResponseEntity.fromJson(response['data']);
  }

  Future<UserEntity> updateUserNickname(String nickname) async {
    final response = await _callFunction(
      name: 'updateUserNickname',
      parameters: <String, dynamic>{
        'nickname': nickname,
      },
    );
    return UserEntity.fromJson(response['data']);
  }

  Future<GameConfigEntity> getGameConfig() async {
    final response = await _callFunction(name: 'getGameConfig');
    return GameConfigEntity.fromJson(response['data']);
  }
}

class _FirebaseFunctionsResponseParser {
  static dynamic parseResponse(dynamic input) {
    if (_isPrimitive(input)) {
      return input;
    }
    if (input is List) {
      return _parseList(input);
    }

    if (input is Map) {
      return _parseMap(input);
    }
    throw StateError('Unable to parse $input as json');
  }

  static bool _isPrimitive(dynamic input) =>
      input is String ||
      input is int ||
      input is double ||
      input is bool ||
      input == null;

  static List<dynamic> _parseList(List input) {
    return input.map((e) {
      if (_isPrimitive(e)) {
        return e;
      }
      if (e is List) {
        return _parseList(e);
      }

      if (e is Map) {
        return _parseMap(e);
      }
      throw StateError('Unable to parse $e as json');
    }).toList();
  }

  static Map<String, dynamic> _parseMap(Map input) => input.entries
      .map((e) {
        final key = e.key as String;
        final value = e.value;
        if (_isPrimitive(value)) {
          return MapEntry(key, value);
        }
        if (value is List) {
          return MapEntry(key, _parseList(value));
        }

        if (value is Map) {
          return MapEntry(key, _parseMap(value));
        }
        throw StateError('Unable to parse $e as json');
      })
      .toList()
      .toMap();
}

DomainError _mapToDomainError(exception) {
  if (exception is DomainError) {
    return exception;
  }
  if (exception is FirebaseFunctionsException) {
    /// I don't know why it is -1004, but it is for network connection error
    if (exception.code == '-1004' || exception.message == 'DEADLINE_EXCEEDED') {
      return NetworkError();
    }
    return ServerError(
      errorEntry: ServerErrorEntry(
        exception.message,
        exception.details,
      ),
    );
  }
  return UnknownError();
}
