import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/data/key_value_storage.dart';
import 'package:save_the_potato/domain/extensions/map_entries_list_extensions.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';

class FirebaseFunctionsWrapper {
  final KeyValueStorage _storage;
  static const _region = 'us-central1';

  FirebaseFunctionsWrapper(this._storage) {
    // if (kDebugMode) {
    //   /// Use the emulator for Cloud Functions if running locally
    //   FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    // }
  }

  Future<dynamic> _callFunction<T>({
    required String name,
    dynamic parameters,
    bool returnFullResponse = false,
  }) async {
    if (kDebugMode) {
      debugPrint('\n-> firebase functions ($name):');
      debugPrint('$parameters');
    }
    final response = await FirebaseFunctions.instanceFor(region: _region)
        .httpsCallable(name)
        .call(parameters);
    final parsedResponse = _FirebaseFunctionsResponseParser.parseResponse(
      response.data,
    );
    if (kDebugMode) {
      debugPrint('\n<- firebase functions ($name):');
      debugPrint('$parsedResponse');
    }
    if (parsedResponse is! Map<String, dynamic>) {
      // Primitive types maybe?
      return parsedResponse;
    }
    return parsedResponse;
  }

  Future<UserEntity> registerUser(String token) async {
    final response = await _callFunction(
      name: 'registerUser',
      parameters: <String, dynamic>{
        'token': token,
      },
    );
    return UserEntity.fromJson(response['data']);
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
