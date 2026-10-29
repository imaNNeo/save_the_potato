import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/double_range.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';

void main() {
  group('Equatable models', () {
    test('compare by props', () {
      expect(
        const DoubleRange(min: 1, max: 2),
        const DoubleRange(min: 1, max: 2),
      );
      expect(
        const DoubleRange(min: 1, max: 2),
        isNot(const DoubleRange(min: 1, max: 3)),
      );
      expect(const ValueWrapper(5), const ValueWrapper(5));
    });

    test('different subclasses with equal props are not equal', () {
      expect(
        const GameModeSingleSpawn() == const GameModeSingleSpawn(),
        isTrue,
      );
      expect(
        ServerError(errorEntry: null) == AccountAlreadyExistsError(email: null),
        isFalse,
      );
    });

    test('errors keep a readable toString', () {
      expect(
        ServerError(errorEntry: ServerErrorEntry('msg', 'details')).toString(),
        'ServerError(ServerErrorEntry(msg, details))',
      );
    });
  });

  test('getHighScoreRepresentation formats mm:ss', () {
    expect(AppUtils.getHighScoreRepresentation(0), '00:00');
    expect(AppUtils.getHighScoreRepresentation(65 * 1000 + 999), '01:05');
  });
}
