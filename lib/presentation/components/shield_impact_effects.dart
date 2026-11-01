import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'damped_spring.dart';
import 'defend_streak.dart';
import 'glow_batch.dart';
import 'moving/orb/orb_type.dart';
import 'sprite_particle_batch.dart';

/// Everything that flies off when an orb crashes into its shield: a white-hot
/// flash, a soft bloom with one ring, a few sparks and shards, and a small
/// kick of the camera.
///
/// Kept light on purpose: blocks happen all the time, so each one is a
/// quick, clean pop that is gone before the next orb arrives.
///
/// It also keeps the [streak] of orbs blocked in a row. The longer it gets,
/// the bigger the impacts and the hotter the shields glow, and every
/// [DefendStreak.milestoneEvery] blocks a ring bursts out of the potato.
/// Getting hit resets it.
///
/// Everything is plain data drawn in a few batched calls, no components.
class ShieldImpactEffects extends Component
    with
        HasGameReference<PotatoGame>,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  ShieldImpactEffects() : super(priority: 2);

  /// How far the camera can be pushed by impacts, in world units
  static const _maxKick = 4.0;

  static const _white = Color(0xFFFFFFFF);

  final streak = DefendStreak();
  double _life = 0;

  final _glow = GlowBatch();
  final _shards = SpriteParticleBatch();
  final _waves = <_Wave>[];
  final _freeWaves = <_Wave>[];
  final _sparks = <_Spark>[];
  final _freeSparks = <_Spark>[];
  final _kicks = <_Kick>[];

  late final Map<OrbType, List<Sprite>> _shardSprites;

  final _kick = Vector2.zero();
  final _appliedKick = Vector2.zero();

  Random get _rnd => game.rnd;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _shardSprites = {
      OrbType.fire: [
        await Sprite.load('sparkle/sparkle1.png'),
        await Sprite.load('sparkle/sparkle2.png'),
      ],
      OrbType.ice: [
        await Sprite.load('snow/snowflake1.png'),
        await Sprite.load('snow/snowflake2.png'),
      ],
    };
  }

  @override
  void onInitialState(GameState state) {
    super.onInitialState(state);
    _life = state.life;
    timeScale = state.gameOverTimeScale;
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.life != newState.life ||
      previousState.gameOverTimeScale != newState.gameOverTimeScale;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    timeScale = state.gameOverTimeScale;
    if (state.life < _life) {
      streak.reset();
    }
    _life = state.life;
  }

  /// An orb of [type] crashed into its shield at [angle] (around [center]),
  /// on the shield's outer edge which is [radius] away from [center].
  void onOrbBlocked({
    required OrbType type,
    required Vector2 center,
    required double angle,
    required double radius,
  }) {
    final isMilestone = streak.block();
    // The hotter and more powered up, the bigger the hit
    final heat = min(1.0, streak.targetHeat + streak.power * 0.35);
    final x = center.x + cos(angle) * radius;
    final y = center.y + sin(angle) * radius;

    _addSplat(x, y, angle, type.colors, heat);
    _addSparks(x, y, angle, type.colors, heat);
    _addShards(x, y, angle, type, heat);
    game.background.block(color: type.intenseColor, angle: angle, heat: heat);

    // Jolt the world the way the orb was flying
    final kick = 1.6 + heat * 0.9;
    _kicks.add(
      _Kick()
        ..x = cos(angle) * kick
        ..y = sin(angle) * kick,
    );

    if (isMilestone) {
      game.background.milestone();
      _nova(center, game.world.player.fireShield.angle);
    }
  }

  /// The orb splats on the shield and a shockwave bounces back out
  void _addSplat(
    double x,
    double y,
    double angle,
    List<Color> colors,
    double heat,
  ) {
    final power = 1 + heat * 0.25;
    _addWave()
      ..x = x
      ..y = y
      ..lifespan = 0.12
      ..fromRadius = 10
      ..toRadius = 18 * power
      ..color = Color.lerp(_white, colors.first, 0.2)!
      ..opacity = 0.9
      ..angle = angle + pi / 2
      ..stretch = 2.0
      ..squash = 0.75
      ..fadePower = 1.6;
    _addWave()
      ..x = x
      ..y = y
      ..lifespan = 0.4
      ..fromRadius = 18
      ..toRadius = 40 * power
      ..color = colors[1]
      ..opacity = 0.45 + heat * 0.15
      ..fadePower = 2.4;
    _addWave()
      ..isRing = true
      ..x = x
      ..y = y
      ..lifespan = 0.4
      ..fromRadius = 10
      ..toRadius = 60 * power
      ..fromWidth = 10
      ..toWidth = 3
      ..color = Color.lerp(colors.first, _white, 0.3)!
      ..opacity = 0.8
      ..fadePower = 2.6
      ..facing = angle
      ..halfSpread = 1.2;
  }

  /// Fast and short lived sparks
  void _addSparks(
    double x,
    double y,
    double angle,
    List<Color> colors,
    double heat,
  ) {
    final rnd = _rnd;
    final difficulty = bloc.state.difficulty;
    final count = 5 + (heat * 3).round() + rnd.nextInt(2);
    for (var i = 0; i < count; i++) {
      final direction = angle + (rnd.nextDouble() + rnd.nextDouble() - 1) * 1.4;
      final speed =
          (260 + 400 * pow(rnd.nextDouble(), 0.8)) *
          (1 + heat * 0.15) *
          (1 + difficulty * 0.15);
      final jitter = (rnd.nextDouble() - 0.5) * 10;
      _addSpark()
        ..x = x - sin(angle) * jitter
        ..y = y + cos(angle) * jitter
        ..vx = cos(direction) * speed
        ..vy = sin(direction) * speed
        ..lifespan = 0.3 + rnd.nextDouble() * 0.2
        ..drag = 4.2 + rnd.nextDouble() * 1.6
        ..width = 2.2 + rnd.nextDouble() * 1.2
        ..headColor = colors.first
        ..tailColor = colors[1 + rnd.nextInt(2)];
    }
  }

  /// A few shards of the orb: its sparkles or snowflakes
  void _addShards(double x, double y, double angle, OrbType type, double heat) {
    final rnd = _rnd;
    final difficulty = bloc.state.difficulty;
    final sprites = _shardSprites[type]!;
    final count = 3 + (heat * 2).round();
    for (var i = 0; i < count; i++) {
      final sprite = sprites.random(rnd);
      final size = 10 + rnd.nextDouble() * 6;
      final direction = angle + (rnd.nextDouble() + rnd.nextDouble() - 1) * 1.2;
      final speed = (90 + rnd.nextDouble() * 160) * (1 + heat * 0.15);
      final jitter = (rnd.nextDouble() - 0.5) * 10;
      final shard =
          _shards.spawn(
              sprite: sprite,
              lifespan:
                  (0.55 + rnd.nextDouble() * 0.3) * (1 - difficulty * 0.25),
            )
            ..color = type.colors.random(rnd)
            ..drag = 2.6
            ..spin = (rnd.nextDouble() * 2 - 1) * 7
            ..drawRotation = rnd.nextDouble() * pi * 2
            ..baseScale = size / sprite.src.width;
      shard.position.setValues(
        x - sin(angle) * jitter,
        y + cos(angle) * jitter,
      );
      shard.speed.setValues(cos(direction) * speed, sin(direction) * speed);
    }
  }

  /// A ring in both colors bursts out of the potato
  void _nova(Vector2 center, double fireAngle) {
    final rnd = _rnd;
    _addWave()
      ..x = center.x
      ..y = center.y
      ..lifespan = 0.5
      ..fromRadius = 70
      ..toRadius = 140
      ..color = _white
      ..opacity = 0.3;
    for (final (type, facing) in [
      (OrbType.fire, fireAngle),
      (OrbType.ice, fireAngle + pi),
    ]) {
      _addWave()
        ..isRing = true
        ..x = center.x
        ..y = center.y
        ..lifespan = 1.0
        ..fromRadius = 70
        ..toRadius = 360
        ..fromWidth = 16
        ..toWidth = 3
        ..color = type.colors[1]
        ..opacity = 0.9
        ..fadePower = 2.2
        ..facing = facing
        ..halfSpread = pi / 2;

      final sprites = _shardSprites[type]!;
      for (var i = 0; i < 5; i++) {
        final direction = facing + (rnd.nextDouble() - 0.5) * pi;
        final speed = 200 + rnd.nextDouble() * 160;
        final sprite = sprites.random(rnd);
        final shard =
            _shards.spawn(
                sprite: sprite,
                lifespan: 1.0 + rnd.nextDouble() * 0.4,
              )
              ..color = type.colors.random(rnd)
              ..drag = 2.5
              ..spin = (rnd.nextDouble() * 2 - 1) * 6
              ..drawRotation = rnd.nextDouble() * pi * 2
              ..baseScale = (12 + rnd.nextDouble() * 6) / sprite.src.width;
        shard.position.setValues(
          center.x + cos(direction) * 75,
          center.y + sin(direction) * 75,
        );
        shard.speed.setValues(cos(direction) * speed, sin(direction) * speed);
      }
    }
  }

  /// A chain of [length] quick blocks is over: the shields bump out
  void _releaseChain(int length) {
    final power = min(1.0, (length - 2) / (DefendStreak.fullChain - 2));
    final player = game.world.player;
    player.fireShield.releaseCharge(power);
    player.iceShield.releaseCharge(power);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final chain = streak.update(dt);
    if (chain >= 3) {
      _releaseChain(chain);
    }

    for (var i = _waves.length - 1; i >= 0; i--) {
      final wave = _waves[i];
      wave.age += dt;
      if (wave.age >= wave.delay + wave.lifespan) {
        _waves[i] = _waves.last;
        _waves.removeLast();
        _freeWaves.add(wave);
      }
    }

    for (var i = _sparks.length - 1; i >= 0; i--) {
      final spark = _sparks[i];
      spark.age += dt;
      if (spark.age >= spark.lifespan) {
        _sparks[i] = _sparks.last;
        _sparks.removeLast();
        _freeSparks.add(spark);
        continue;
      }
      final slowDown = exp(-spark.drag * dt);
      spark.vx *= slowDown;
      spark.vy *= slowDown;
      spark.x += spark.vx * dt;
      spark.y += spark.vy * dt;
    }

    _shards.update(dt);
    _updateCameraKick(dt);

    final state = bloc.state;
    game.background.update(
      dt,
      heat: streak.heat,
      power: streak.power,
      multiOrbWave:
          state.playingState.isPlaying &&
          (state.currentGameMode is GameModeMultiSpawn ||
              state.upcomingGameMode is GameModeMultiSpawn),
      kickX: _appliedKick.x,
      kickY: _appliedKick.y,
    );
  }

  void _updateCameraKick(double dt) {
    _kick.setZero();
    for (var i = _kicks.length - 1; i >= 0; i--) {
      final kick = _kicks[i];
      kick.age += dt;
      if (kick.age >= _Kick.duration) {
        _kicks[i] = _kicks.last;
        _kicks.removeLast();
        continue;
      }
      final strength = kick.strength;
      _kick.x += kick.x * strength;
      _kick.y += kick.y * strength;
    }
    if (_kick.length2 > _maxKick * _maxKick) {
      _kick.scaleTo(_maxKick);
    }
    final dx = _kick.x - _appliedKick.x, dy = _kick.y - _appliedKick.y;
    if (dx != 0 || dy != 0) {
      // Moved by the difference only, so other camera effects still work.
      // The viewfinder's position getter returns a copy, set it back.
      final viewfinder = game.camera.viewfinder;
      viewfinder.position = viewfinder.position
        ..x += dx
        ..y += dy;
      _appliedKick.setFrom(_kick);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _shards.render(canvas, _prepareShard);

    _glow.clear();
    for (final wave in _waves) {
      final t = (wave.age - wave.delay) / wave.lifespan;
      if (t < 0) {
        continue;
      }
      final grow = 1 - pow(1 - t, 3).toDouble();
      final radius = lerpDouble(wave.fromRadius, wave.toRadius, grow)!;
      final opacity = wave.opacity * pow(1 - t, wave.fadePower);
      if (wave.isRing) {
        _glow.addRing(
          wave.x,
          wave.y,
          radius,
          lerpDouble(wave.fromWidth, wave.toWidth, grow)!,
          wave.color,
          opacity,
          facing: wave.facing,
          halfSpread: wave.halfSpread,
        );
      } else {
        _glow.addDisc(
          wave.x,
          wave.y,
          radius,
          wave.color,
          opacity,
          angle: wave.angle,
          stretch: wave.stretch,
          squash: wave.squash,
        );
      }
    }
    for (final spark in _sparks) {
      final t = spark.age / spark.lifespan;
      final speed = sqrt(spark.vx * spark.vx + spark.vy * spark.vy);
      if (speed < 1) {
        continue;
      }
      // Fast sparks leave longer streaks
      final length = (speed * 0.06).clamp(2.0, 34.0);
      _glow.addStreak(
        spark.x,
        spark.y,
        spark.x - spark.vx / speed * length,
        spark.y - spark.vy / speed * length,
        spark.width * (1 - t * 0.5),
        Color.lerp(_white, spark.headColor, t)!,
        spark.tailColor,
        pow(1 - t, 1.3).toDouble(),
      );
    }
    _glow.render(canvas);
  }

  bool _prepareShard(SpriteParticle shard) {
    final t = shard.progress;
    final scale = 1 - pow(t, 2.2);
    final opacity = 1 - pow(t, 3);
    if (scale <= 0.01 || opacity <= 0.01) {
      return false;
    }
    shard.drawScale = shard.baseScale * scale;
    shard.drawOpacity = opacity.toDouble();
    return true;
  }

  _Wave _addWave() {
    final wave = (_freeWaves.isNotEmpty ? _freeWaves.removeLast() : _Wave())
      ..reset();
    _waves.add(wave);
    return wave;
  }

  _Spark _addSpark() {
    final spark = _freeSparks.isNotEmpty ? _freeSparks.removeLast() : _Spark();
    spark.age = 0;
    _sparks.add(spark);
    return spark;
  }

  @override
  void onRemove() {
    _shards.clear();
    _waves.clear();
    _sparks.clear();
    _kicks.clear();
    super.onRemove();
  }
}

/// A glowing disc or ring that grows and fades out
class _Wave {
  bool isRing = false;
  double x = 0, y = 0;
  double age = 0;
  double delay = 0;
  double lifespan = 1;
  double fromRadius = 0, toRadius = 0;
  double fromWidth = 0, toWidth = 0;
  Color color = const Color(0xFFFFFFFF);
  double opacity = 1;
  double fadePower = 2;

  /// Rings only: the side of the ring that is visible
  double? facing;
  double halfSpread = pi / 2;

  /// Discs only: stretched along [angle] and squashed across it
  double angle = 0;
  double stretch = 1;
  double squash = 1;

  void reset() {
    isRing = false;
    age = 0;
    delay = 0;
    fromWidth = toWidth = 0;
    opacity = 1;
    fadePower = 2;
    facing = null;
    halfSpread = pi / 2;
    angle = 0;
    stretch = squash = 1;
  }
}

class _Spark {
  double x = 0, y = 0;
  double vx = 0, vy = 0;
  double age = 0;
  double lifespan = 1;
  double drag = 0;
  double width = 1;
  Color headColor = const Color(0xFFFFFFFF);
  Color tailColor = const Color(0xFFFFFFFF);
}

/// The camera is pushed by [x], [y] and springs back.
class _Kick {
  static const duration = 0.3;
  static final _spring = DampedSpring(frequency: 2 * pi * 7, damping: 0.45);

  double x = 0, y = 0;
  double age = 0;

  double get strength => _spring.at(age);
}
