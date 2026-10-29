import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'glow_batch.dart';
import 'moving/moving_components.dart';
import 'moving/orb/orb_type.dart';
import 'sprite_particle_batch.dart';

/// Everything that makes the flying orbs look alive: a glowing comet tail,
/// a flickering (fire) or breathing (ice) halo, the sparkles or snowflakes
/// they leave behind, flame puffs or frost mist, and embers or twinkling
/// frost glints.
///
/// When an orb is blocked or hits the potato, its tail snaps into the spot
/// where it ended instead of disappearing at once.
///
/// The orbs only register here, everything is plain data drawn in two
/// batched calls (one [GlowBatch] and one atlas per sprite image), no
/// components per orb or per particle.
class OrbEffects extends Component
    with
        HasGameReference<PotatoGame>,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  /// Under the orbs (their priority is 1), so the heads cover the glow
  OrbEffects() : super(priority: 0);

  static const _white = Color(0xFFFFFFFF);

  /// How often each orb drops a pair of sparkles, as it always did
  static const _sparkleEvery = 0.04;

  /// How often each orb puffs a bit of flame or mist
  static const _puffEvery = 0.05;

  /// How often each orb throws an ember or a frost glint
  static const _moteEvery = 0.035;

  /// The tail snaps into the hit point in this long
  static const _ghostLifespan = 0.16;

  final _orbs = <MovingOrb>[];
  final _glow = GlowBatch();
  final _sparkles = SpriteParticleBatch();
  final _puffs = <_Puff>[];
  final _freePuffs = <_Puff>[];
  final _motes = <_Mote>[];
  final _freeMotes = <_Mote>[];
  final _ghosts = <_Ghost>[];

  late final Map<OrbType, List<Sprite>> _sparkleSprites;

  Random get _rnd => game.rnd;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sparkleSprites = {
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
    timeScale = state.gameOverTimeScale;
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.gameOverTimeScale != newState.gameOverTimeScale;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    timeScale = state.gameOverTimeScale;
  }

  void track(MovingOrb orb) {
    if (!_orbs.contains(orb)) {
      _orbs.add(orb);
    }
  }

  /// The orb is gone: blocked, hit the potato, or the game is over
  void untrack(MovingOrb orb) {
    if (!_orbs.remove(orb) || !orb.isFlying) {
      return;
    }
    final direction = orb.direction;
    _ghosts.add(
      _Ghost()
        ..type = orb.type
        ..x = orb.position.x
        ..y = orb.position.y
        ..dx = direction.x
        ..dy = direction.y
        ..length = _tailLength(orb)
        ..width = orb.size.x,
    );
  }

  static double _tailLength(MovingOrb orb) =>
      (orb.speed * 0.42).clamp(40.0, 110.0) * (orb.type.isFire ? 1.0 : 0.85);

  @override
  void update(double dt) {
    super.update(dt);
    for (final orb in _orbs) {
      if (!orb.isFlying) {
        continue;
      }
      orb.effectsTime += dt;
      final t = orb.effectsTime + orb.seed;
      // The head swells a little with the flicker or the breath
      orb.pulse = orb.type.isFire
          ? 1 + 0.05 * sin(t * 29)
          : 1 + 0.04 * sin(t * 4.5);
      orb.sparkleClock += dt;
      orb.puffClock += dt;
      orb.moteClock += dt;
      if (orb.sparkleClock >= _sparkleEvery) {
        orb.sparkleClock -= _sparkleEvery;
        _addSparkles(orb);
      }
      if (orb.puffClock >= _puffEvery) {
        orb.puffClock -= _puffEvery;
        _addPuff(orb);
      }
      if (orb.moteClock >= _moteEvery) {
        orb.moteClock -= _moteEvery;
        _addMote(orb);
      }
    }

    _sparkles.update(dt);

    for (var i = _puffs.length - 1; i >= 0; i--) {
      final puff = _puffs[i];
      puff.age += dt;
      if (puff.age >= puff.lifespan) {
        _puffs[i] = _puffs.last;
        _puffs.removeLast();
        _freePuffs.add(puff);
        continue;
      }
      puff.x += puff.vx * dt;
      puff.y += puff.vy * dt;
    }

    for (var i = _motes.length - 1; i >= 0; i--) {
      final mote = _motes[i];
      mote.age += dt;
      if (mote.age >= mote.delay + mote.lifespan) {
        _motes[i] = _motes.last;
        _motes.removeLast();
        _freeMotes.add(mote);
        continue;
      }
      if (mote.age < mote.delay) {
        continue;
      }
      final slowDown = exp(-mote.drag * dt);
      mote.vx *= slowDown;
      mote.vy *= slowDown;
      mote.x += mote.vx * dt;
      mote.y += mote.vy * dt;
    }

    for (var i = _ghosts.length - 1; i >= 0; i--) {
      final ghost = _ghosts[i];
      ghost.age += dt;
      if (ghost.age >= _ghostLifespan) {
        _ghosts[i] = _ghosts.last;
        _ghosts.removeLast();
      }
    }
  }

  /// The sparkles or snowflakes the orbs always left behind them, now
  /// drifting a little off the path while they spin and shrink
  void _addSparkles(MovingOrb orb) {
    final rnd = _rnd;
    final type = orb.type;
    final sprites = _sparkleSprites[type]!;
    final direction = orb.direction;
    for (var i = 0; i < 2; i++) {
      final sprite = sprites[rnd.nextInt(sprites.length)];
      final from = rnd.nextInt(3);
      // Half keep one color, the others shift through the palette
      final to = rnd.nextBool() ? from : rnd.nextInt(3);
      final sparkle = _sparkles.spawn(sprite: sprite, lifespan: 1.2)
        ..color = type.colors[from]
        ..kind = type.index * 9 + from * 3 + to
        ..spin = (rnd.nextBool() ? 1 : -1) * (pi * 2 / 1.2)
        ..drawRotation = rnd.nextDouble() * pi * 2
        ..drag = 2.0
        ..baseScale = orb.size.x * orb.trailSizeMultiplier / sprite.src.width;
      final side = (rnd.nextDouble() * 2 - 1) * 30;
      sparkle.position.setValues(
        orb.position.x - direction.y * side * 0.12,
        orb.position.y + direction.x * side * 0.12,
      );
      sparkle.speed.setValues(-direction.y * side, direction.x * side);
    }
  }

  /// Fire leaves puffs of flame that cool down, ice leaves cold mist
  void _addPuff(MovingOrb orb) {
    final rnd = _rnd;
    final direction = orb.direction;
    final isFire = orb.type.isFire;
    final side = (rnd.nextDouble() * 2 - 1) * (isFire ? 18 : 10);
    final puff = (_freePuffs.isNotEmpty ? _freePuffs.removeLast() : _Puff())
      ..type = orb.type
      ..age = 0
      ..lifespan = isFire
          ? 0.32 + rnd.nextDouble() * 0.12
          : 0.55 + rnd.nextDouble() * 0.2
      ..x = orb.position.x
      ..y = orb.position.y
      ..vx = -direction.x * orb.speed * 0.1 - direction.y * side
      ..vy = -direction.y * orb.speed * 0.1 + direction.x * side
      ..fromRadius = orb.size.x * (isFire ? 0.7 : 0.6)
      ..toRadius = orb.size.x * (isFire ? 1.5 : 1.9);
    _puffs.add(puff);
  }

  /// Fire throws hot embers, ice drops twinkling frost glints
  void _addMote(MovingOrb orb) {
    final rnd = _rnd;
    final direction = orb.direction;
    final isFire = orb.type.isFire;
    final radius = orb.size.x / 2;
    final sideSign = rnd.nextBool() ? 1.0 : -1.0;
    // Starts behind the head, so the shine stays in the trail
    final along = radius * (0.6 + rnd.nextDouble());
    final across = sideSign * radius * (0.4 + rnd.nextDouble() * 0.6);
    final mote = (_freeMotes.isNotEmpty ? _freeMotes.removeLast() : _Mote())
      ..type = orb.type
      ..age = 0
      ..x = orb.position.x - direction.x * along - direction.y * across
      ..y = orb.position.y - direction.y * along + direction.x * across
      ..phase = rnd.nextDouble() * pi * 2
      ..delay = 0
      ..fire = _FireMote.ember;
    if (isFire) {
      final out = 45 + rnd.nextDouble() * 65;
      final back = orb.speed * (0.1 + rnd.nextDouble() * 0.15);
      mote
        ..lifespan = 0.6 + rnd.nextDouble() * 0.4
        ..vx = -direction.x * back - direction.y * out * sideSign
        ..vy = -direction.y * back + direction.x * out * sideSign
        ..drag = 2.2
        ..size = 2.0 + rnd.nextDouble() * 1.4;
      if (rnd.nextDouble() < 0.15) {
        _addCrackle(orb);
      }
    } else {
      final out = 8 + rnd.nextDouble() * 18;
      mote
        ..lifespan = 0.6 + rnd.nextDouble() * 0.4
        ..vx = -direction.y * out * sideSign
        ..vy = direction.x * out * sideSign
        ..drag = 1.5
        ..size = 2.5 + rnd.nextDouble() * 3.5;
    }
    _motes.add(mote);
  }

  _Mote _addFireMote(double x, double y, _FireMote kind, double delay) {
    final mote = (_freeMotes.isNotEmpty ? _freeMotes.removeLast() : _Mote())
      ..type = OrbType.fire
      ..fire = kind
      ..age = 0
      ..delay = delay
      ..x = x
      ..y = y
      ..vx = 0
      ..vy = 0
      ..drag = 0
      ..phase = 0;
    _motes.add(mote);
    return mote;
  }

  /// A spot of the fire trail that pops a moment after the orb passed:
  /// a flash and a few sparks, so the trail keeps crackling behind it
  void _addCrackle(MovingOrb orb) {
    final rnd = _rnd;
    final direction = orb.direction;
    final back = 8 + rnd.nextDouble() * 30;
    final across = (rnd.nextDouble() * 2 - 1) * orb.size.x * 0.6;
    final x = orb.position.x - direction.x * back - direction.y * across;
    final y = orb.position.y - direction.y * back + direction.x * across;
    final delay = 0.12 + rnd.nextDouble() * 0.2;
    _addFireMote(x, y, _FireMote.crackleFlash, delay)
      ..lifespan = 0.24
      ..size = 7 + rnd.nextDouble() * 4;
    final count = 3 + rnd.nextInt(2);
    final turn = rnd.nextDouble() * pi * 2;
    for (var i = 0; i < count; i++) {
      final angle = turn + i * pi * 2 / count + (rnd.nextDouble() - 0.5) * 0.6;
      final speed = 90 + rnd.nextDouble() * 70;
      _addFireMote(x, y, _FireMote.crackleSpark, delay)
        ..lifespan = 0.22 + rnd.nextDouble() * 0.14
        ..vx = cos(angle) * speed
        ..vy = sin(angle) * speed
        ..drag = 6
        ..size = 1.1 + rnd.nextDouble() * 0.4;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _glow.clear();
    _addPuffsGlow();
    for (final ghost in _ghosts) {
      _addGhostGlow(ghost);
    }
    for (final orb in _orbs) {
      if (orb.isFlying) {
        _addOrbGlow(orb);
      }
    }
    _addMotesGlow();
    _glow.render(canvas);
    // On top of the glow, so they keep their colors
    _sparkles.render(canvas, _prepareSparkle);
  }

  void _addPuffsGlow() {
    for (final puff in _puffs) {
      final t = puff.age / puff.lifespan;
      final colors = puff.type.colors;
      final grow = 1 - (1 - t) * (1 - t);
      final radius = lerpDouble(puff.fromRadius, puff.toRadius, grow)!;
      if (puff.type.isFire) {
        // Hot orange cooling down to deep red
        _glow.addDisc(
          puff.x,
          puff.y,
          radius,
          Color.lerp(colors[1], colors[2], t)!,
          0.38 * pow(1 - t, 1.6),
        );
      } else {
        _glow.addDisc(
          puff.x,
          puff.y,
          radius,
          Color.lerp(colors[1], colors[2], t * 0.6)!,
          0.22 * sin(pi * min(1.0, t * 1.6 + 0.15)).clamp(0.0, 1.0),
        );
      }
    }
  }

  void _addOrbGlow(MovingOrb orb) {
    final direction = orb.direction;
    if (direction.x == 0 && direction.y == 0) {
      return;
    }
    final colors = orb.type.colors;
    final x = orb.position.x, y = orb.position.y;
    final size = orb.size.x;
    final t = orb.effectsTime + orb.seed;
    final isFire = orb.type.isFire;

    // Gets a little brighter as it closes in on the potato
    final potato = game.world.player.position;
    final distance = orb.position.distanceTo(potato);
    final danger = (1 - distance / (game.size.x * 0.5)).clamp(0.0, 1.0);

    // Fire flickers fast and unevenly, ice breathes slowly
    final flicker = isFire
        ? 1 + 0.12 * sin(t * 23) + 0.08 * sin(t * 37 + 1.3)
        : 1 + 0.07 * sin(t * 4.5);

    final length = _tailLength(orb) * (isFire ? flicker : 1);
    _addTails(
      orb.type,
      x,
      y,
      direction.x,
      direction.y,
      length,
      size * (isFire ? flicker : 1),
      0.7 + danger * 0.25,
      t,
    );

    // The halo around the head
    _glow.addDisc(x, y, size * 1.4 * flicker, colors[1], 0.4 + danger * 0.15);

    // A warning that beats faster and harder the closer it gets
    if (danger > 0.05) {
      final beat = 0.5 + 0.5 * sin(t * (5 + danger * 13));
      _glow.addRing(
        x,
        y,
        size * (1.0 + 0.35 * beat),
        size * 0.45,
        colors[2],
        pow(danger, 1.4) * (0.25 + 0.55 * beat),
      );
    }
  }

  /// The tail of a gone orb catches up with where the orb ended
  void _addGhostGlow(_Ghost ghost) {
    final t = ghost.age / _ghostLifespan;
    final length = ghost.length * pow(1 - t, 1.5);
    if (length < 1) {
      return;
    }
    _addTails(
      ghost.type,
      ghost.x,
      ghost.y,
      ghost.dx,
      ghost.dy,
      length,
      ghost.width * (1 - t * 0.4),
      0.7 * (1 - t),
      ghost.age,
    );
  }

  /// A wide soft tail with a hot core. Fire's wiggles like a flame.
  void _addTails(
    OrbType type,
    double x,
    double y,
    double dx,
    double dy,
    double length,
    double size,
    double opacity,
    double time,
  ) {
    final colors = type.colors;
    final isFire = type.isFire;
    _glow.addTail(
      x,
      y,
      dx,
      dy,
      length,
      size * 2.1,
      colors[1],
      colors[2],
      opacity,
      wave: isFire ? size * 0.35 : 0,
      wavePhase: time * 16,
    );
    _glow.addTail(
      x,
      y,
      dx,
      dy,
      length * 0.65,
      size * 0.9,
      Color.lerp(colors.first, _white, 0.5)!,
      colors[1],
      opacity * 1.1,
      wave: isFire ? size * 0.15 : 0,
      wavePhase: time * 16 + 0.6,
      segments: 6,
    );
  }

  void _addMotesGlow() {
    for (final mote in _motes) {
      final age = mote.age - mote.delay;
      if (age < 0) {
        continue;
      }
      final t = age / mote.lifespan;
      final colors = mote.type.colors;
      if (mote.type.isFire) {
        _addFireMoteGlow(mote, age, t, colors);
      } else {
        // Frost glints pop in, twinkle and fade
        final twinkle = 0.5 + 0.5 * sin(mote.age * 18 + mote.phase);
        final opacity = 0.8 * sin(pi * t) * (0.45 + 0.55 * twinkle);
        final reach = mote.size * (0.6 + 0.4 * twinkle);
        _glow.addDisc(
          mote.x,
          mote.y,
          mote.size * 1.6,
          colors[1],
          opacity * 0.6,
        );
        _glow.addStreak(
          mote.x + reach,
          mote.y,
          mote.x - reach,
          mote.y,
          1.6,
          _white,
          colors.first,
          opacity,
        );
        _glow.addStreak(
          mote.x - reach,
          mote.y,
          mote.x + reach,
          mote.y,
          1.6,
          _white,
          colors.first,
          opacity,
        );
        _glow.addStreak(
          mote.x,
          mote.y + reach,
          mote.x,
          mote.y - reach,
          1.6,
          _white,
          colors.first,
          opacity,
        );
        _glow.addStreak(
          mote.x,
          mote.y - reach,
          mote.x,
          mote.y + reach,
          1.6,
          _white,
          colors.first,
          opacity,
        );
      }
    }
  }

  void _addFireMoteGlow(_Mote mote, double age, double t, List<Color> colors) {
    switch (mote.fire) {
      case _FireMote.ember:
        // Dim when it leaves the orb, flares up white-hot as it drifts
        // away, then cools down to deep red and dies out
        final flare = sin(pi * pow(t, 0.75)).clamp(0.0, 1.0);
        final flicker = 0.75 + 0.25 * sin(age * 38 + mote.phase);
        final glow = flare * flicker;
        _glow.addDisc(
          mote.x,
          mote.y,
          mote.size * (1.8 + 1.2 * flare),
          Color.lerp(colors[1], colors[2], t)!,
          0.3 * glow,
        );
        final speed = sqrt(mote.vx * mote.vx + mote.vy * mote.vy);
        if (speed < 1) {
          return;
        }
        final length = (speed * 0.08).clamp(2.0, 10.0);
        _glow.addStreak(
          mote.x,
          mote.y,
          mote.x - mote.vx / speed * length,
          mote.y - mote.vy / speed * length,
          mote.size * (1.2 + flare * 0.5),
          t < 0.5
              ? Color.lerp(colors[1], _white, flare)!
              : Color.lerp(colors[2], _white, flare * 0.8)!,
          colors[2],
          0.3 + 0.55 * glow,
        );
        // At its hottest it shines like a little star, turned so it doesn't
        // look like the ice glints
        if (flare > 0.35) {
          final shine = 0.8 * (flare - 0.35) / 0.65 * flicker;
          final reach = mote.size * (1.0 + 0.8 * shine);
          final d = reach * 0.7071;
          _glow.addDisc(
            mote.x,
            mote.y,
            mote.size * 1.6,
            colors[1],
            0.6 * shine,
          );
          for (final (dx, dy) in [(d, d), (d, -d)]) {
            _glow.addStreak(
              mote.x + dx,
              mote.y + dy,
              mote.x - dx,
              mote.y - dy,
              1.6,
              _white,
              colors.first,
              shine,
            );
            _glow.addStreak(
              mote.x - dx,
              mote.y - dy,
              mote.x + dx,
              mote.y + dy,
              1.6,
              _white,
              colors.first,
              shine,
            );
          }
        }
      case _FireMote.crackleFlash:
        final grow = 1 - (1 - t) * (1 - t);
        _glow.addDisc(
          mote.x,
          mote.y,
          mote.size * (0.4 + 0.6 * grow),
          Color.lerp(colors.first, colors[1], t)!,
          0.6 * pow(1 - t, 2),
        );
      case _FireMote.crackleSpark:
        final speed = sqrt(mote.vx * mote.vx + mote.vy * mote.vy);
        if (speed < 1) {
          return;
        }
        final length = (speed * 0.07).clamp(1.5, 8.0);
        _glow.addStreak(
          mote.x,
          mote.y,
          mote.x - mote.vx / speed * length,
          mote.y - mote.vy / speed * length,
          mote.size * 1.6,
          Color.lerp(_white, colors.first, t)!,
          colors[1],
          0.8 * pow(1 - t, 1.4),
        );
    }
  }

  bool _prepareSparkle(SpriteParticle sparkle) {
    final t = sparkle.progress;
    // Fades like the old trail particles (easeOutQuart), but dimmer, so the
    // trail doesn't glitter like a pickup
    final opacity = 0.55 * pow(1 - t, 4);
    if (opacity <= 0.01) {
      return false;
    }
    final kind = sparkle.kind;
    final colors = OrbType.values[kind ~/ 9].colors;
    final from = (kind % 9) ~/ 3, to = kind % 3;
    if (from != to) {
      sparkle.color = Color.lerp(colors[from], colors[to], t)!;
    }
    sparkle.drawScale = sparkle.baseScale * (1 - t);
    sparkle.drawOpacity = opacity.toDouble();
    return true;
  }

  @override
  void onRemove() {
    _orbs.clear();
    _sparkles.clear();
    _puffs.clear();
    _motes.clear();
    _ghosts.clear();
    super.onRemove();
  }
}

/// A soft disc of flame or mist left behind on the path
class _Puff {
  OrbType type = OrbType.fire;
  double x = 0, y = 0;
  double vx = 0, vy = 0;
  double age = 0;
  double lifespan = 1;
  double fromRadius = 0, toRadius = 0;
}

/// An ember (fire) or a frost glint (ice)
class _Mote {
  OrbType type = OrbType.fire;
  double x = 0, y = 0;
  double vx = 0, vy = 0;
  double age = 0;
  double lifespan = 1;
  double drag = 0;
  double size = 1;
  double phase = 0;

  /// Waits this long before it shows up and starts moving
  double delay = 0;

  /// What kind of fire mote it is, ice motes are always glints
  _FireMote fire = _FireMote.ember;
}

enum _FireMote {
  /// Drifts off the orb and flares up white-hot before it cools down
  ember,

  /// Bursts out of a crackle that pops behind the orb
  crackleSpark,

  /// The flash of a crackle
  crackleFlash,
}

/// The tail of an orb that is gone
class _Ghost {
  OrbType type = OrbType.fire;
  double x = 0, y = 0;
  double dx = 0, dy = 0;
  double length = 0;
  double width = 0;
  double age = 0;
}
