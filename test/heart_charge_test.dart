import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';

class _Fake {
  final calls = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    return null;
  }
}

class _FakeAudio extends _Fake implements AudioHelper {}

class _FakeScores extends _Fake implements ScoresRepository {}

class _FakeConfigs extends _Fake implements ConfigsRepository {}

class _FakeAnalytics extends _Fake implements AnalyticsHelper {}

void main() {
  const n = GameConstants.blocksToEarnHeart;
  late _FakeAudio audio;
  late _FakeAnalytics analytics;
  late GameCubit cubit;

  setUp(() {
    audio = _FakeAudio();
    analytics = _FakeAnalytics();
    cubit = GameCubit(audio, _FakeScores(), _FakeConfigs(), analytics);
  });

  void block(int times) {
    for (var i = 0; i < times; i++) {
      cubit.onShieldHit();
    }
  }

  test('blocking does not charge a heart while all hearts are there', () {
    block(n * 2);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints);
    expect(cubit.state.heartCharge, 0);
  });

  test('blocking in a row earns a missing heart back', () {
    cubit.potatoOrbHit();
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints - 1);

    block(n - 1);
    expect(cubit.state.heartCharge, n - 1);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints - 1);

    block(1);
    expect(cubit.state.heartCharge, 0);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints);
    expect(analytics.calls, contains(#heartReceived));
    expect(audio.calls, contains(#playHeartHitSound));

    // Full again, so it stops charging
    block(n);
    expect(cubit.state.heartCharge, 0);
  });

  test('getting hit empties the heart', () {
    cubit.potatoOrbHit();
    block(n - 1);
    cubit.potatoOrbHit();
    expect(cubit.state.heartCharge, 0);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints - 2);

    // Has to start over: n - 1 blocks are not enough
    block(n - 1);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints - 2);
    block(1);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints - 1);
  });

  test('two missing hearts take two full charges', () {
    cubit.potatoOrbHit();
    cubit.potatoOrbHit();
    block(n);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints - 1);
    block(n);
    expect(cubit.state.healthPoints, GameConstants.maxHealthPoints);
  });
}
