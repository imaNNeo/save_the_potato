import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:save_the_potato/presentation/helpers/tense_style/tense_style_override.dart';

/// What the stars background (`shaders/background.frag`) should be doing to
/// follow the game: the game tells it what happened (an orb blocked, a chain
/// released, the potato getting hit, ...) and updates it every frame, and the
/// background reads it when it paints.
///
/// It's plain numbers, so it costs nothing when nothing happens. It notifies
/// its listeners on every [update] while something is still moving, so the
/// background keeps repainting even when the stars themselves are frozen
/// (e.g. the game over slow motion).
class BackgroundReactions extends ChangeNotifier {
  /// How many shockwaves the shader can draw at once
  static const maxWaves = 4;

  static const _white = Color(0xFFFFFFFF);
  static const _hitColor = Color(0xFFFF1E3C);
  static const _healColor = Color(0xFFFF4D8D);

  final waves = List.generate(maxWaves, (_) => BackgroundWave());

  /// Follows the defend streak's heat, from 0 to 1
  double heat = 0;

  /// Follows the shields' power jolts, from 0 to 1. Stretches the stars into
  /// streaks and speeds them up.
  double power = 0;

  /// From 1 right after the potato got hit, quickly back to 0
  double hit = 0;

  /// Bright flash of the center glow, from 1 right after a block or a
  /// milestone, quickly back to 0
  double flash = 0;

  /// How the background shows that a wave of multiple orbs is coming
  static TenseStyle tenseStyle = TenseStyle.values.firstWhere(
    (style) => style.name == tenseStyleOverride(),
    orElse: () => TenseStyle.rush,
  );

  /// Eases towards 1 from when a wave of multiple orbs is announced until
  /// it's over
  double tension = 0;

  /// Eases towards 1 while the wave's orbs are actually flying in
  double waveActive = 0;

  /// The lanes the wave's orbs fly in on, see [updateLanes]
  final lanes = List.generate(2, (_) => BackgroundLane());

  /// A few long streaks gliding out past the stars, from 0 to 1
  double get streaks => tenseStyle == TenseStyle.rush ? tension : 0;

  /// How much the stars are dimmed, from 0 to 1
  double get dim =>
      tenseStyle == TenseStyle.hush ? tension * (1 - waveActive) * 0.8 : 0;

  /// How much the stars are stretched into streaks, from 0 to 1. Negative
  /// stretches them outwards, for stars flying in.
  double get stretch => switch (tenseStyle) {
    TenseStyle.rush => max(power, tension * 0.35),
    TenseStyle.inward => tension > 0.5 ? -max(power, tension * 0.35) : power,
    TenseStyle.hush => max(power, waveActive * 0.45),
    TenseStyle.lanes => power,
  };

  /// How much faster than usual the stars should fly right now, negative
  /// flies them in towards the potato
  double get speedBoost {
    final base = 1 + power * 1.8 + heat * 0.35;
    return switch (tenseStyle) {
      TenseStyle.rush => base + tension * 2.2,
      TenseStyle.inward => base * (1 - tension * 2.4),
      TenseStyle.hush => base * (1 - dim) + waveActive * 2.5,
      TenseStyle.lanes => base + tension * 0.6,
    };
  }

  /// Offset of the stars in world units, follows the camera kicks and shakes
  /// when the potato is hit
  double shakeX = 0;
  double shakeY = 0;

  /// Color of the glow around the potato, drifts towards the color of the
  /// last blocked orb
  double glowR = 1, glowG = 1, glowB = 1;
  Color _glowTarget = _white;

  double _hitTime = 0;

  bool get _isActive =>
      power > 0.001 ||
      hit > 0.001 ||
      flash > 0.001 ||
      tension > 0.001 ||
      lanes.any((lane) => lane.amount > 0.001) ||
      shakeX.abs() > 0.01 ||
      shakeY.abs() > 0.01 ||
      waves.any((wave) => wave.isActive);

  /// An orb of [color] got blocked at [angle] around the potato
  void block({required Color color, required double angle, double heat = 0}) {
    _glowTarget = color;
    flash = min(1.0, flash + 0.45 + heat * 0.3);
    _addWave(
      color: Color.lerp(color, _white, 0.15)!,
      angle: angle,
      focus: 0.8,
      fromRadius: 80,
      toRadius: 520 + heat * 260,
      lifespan: 0.9 + heat * 0.35,
      intensity: 0.55 + heat * 0.45,
    );
  }

  /// A chain of quick blocks got released, [strength] from 0 to 1
  void chain(double strength) {
    _addWave(
      color: Color.lerp(_glowTarget, _white, 0.35)!,
      angle: 0,
      focus: 0,
      fromRadius: 80,
      toRadius: 700 + strength * 300,
      lifespan: 1.1 + strength * 0.4,
      intensity: 0.6 + strength * 0.4,
    );
  }

  /// The streak reached a milestone
  void milestone() {
    flash = 1;
    _addWave(
      color: _white,
      angle: 0,
      focus: 0,
      fromRadius: 60,
      toRadius: 1100,
      lifespan: 1.6,
      intensity: 1.1,
    );
  }

  /// An orb got through and hit the potato, coming from [angle]
  void potatoHit(double angle) {
    hit = 1;
    _hitTime = 0;
    flash = 0;
    _glowTarget = _hitColor;
    _addWave(
      color: _hitColor,
      angle: angle,
      focus: 0.45,
      fromRadius: 40,
      toRadius: 900,
      lifespan: 1.2,
      intensity: 1.1,
    );
  }

  /// The potato got a health point back
  void healed() {
    _glowTarget = _healColor;
    flash = min(1.0, flash + 0.5);
    _addWave(
      color: _healColor,
      angle: 0,
      focus: 0,
      fromRadius: 50,
      toRadius: 650,
      lifespan: 1.1,
      intensity: 0.7,
    );
  }

  /// A wave's orbs are flying in from [angle] (around the potato), in
  /// [color]. Called every frame for every lane while the wave lasts.
  void updateLanes(double angle, Color color) {
    final dirX = cos(angle), dirY = sin(angle);
    // Keep each lane in the same slot, so it fades instead of jumping. More
    // spawners than slots (one wave ending as the next starts) are skipped.
    BackgroundLane? slot;
    for (final lane in lanes) {
      if (lane._present) continue;
      if (lane.amount > 0.01 && lane.dirX * dirX + lane.dirY * dirY > 0.9) {
        slot = lane;
        break;
      }
      if (slot == null || lane.amount < slot.amount) {
        slot = lane;
      }
    }
    if (slot == null) {
      return;
    }
    slot
      ..dirX = dirX
      ..dirY = dirY
      ..r = color.r
      ..g = color.g
      ..b = color.b
      .._present = true;
  }

  void _addWave({
    required Color color,
    required double angle,
    required double focus,
    required double fromRadius,
    required double toRadius,
    required double lifespan,
    required double intensity,
  }) {
    // Take a free slot, or the one that is the closest to fading out
    var slot = waves.first;
    for (final wave in waves) {
      if (!wave.isActive) {
        slot = wave;
        break;
      }
      if (wave.progress > slot.progress) {
        slot = wave;
      }
    }
    slot
      ..age = 0
      ..lifespan = lifespan
      ..fromRadius = fromRadius
      ..toRadius = toRadius
      ..peak = intensity
      ..dirX = cos(angle)
      ..dirY = sin(angle)
      ..focus = focus
      ..r = color.r
      ..g = color.g
      ..b = color.b;
  }

  /// Called by the game every frame
  void update(
    double dt, {
    required double heat,
    required double power,
    required bool multiOrbWave,
    bool multiOrbWaveFlying = false,
    required double kickX,
    required double kickY,
  }) {
    final wasActive = _isActive;
    this.heat = heat;
    this.power = power;

    for (final wave in waves) {
      if (wave.isActive) {
        wave.age += dt;
      }
    }

    flash *= exp(-5 * dt);
    _hitTime += dt;
    hit *= exp(-2.6 * dt);

    final ease = 1 - exp(-1.5 * dt);
    tension += ((multiOrbWave ? 1.0 : 0.0) - tension) * ease;
    waveActive += ((multiOrbWaveFlying ? 1.0 : 0.0) - waveActive) * ease;
    final showLanes = tenseStyle == TenseStyle.lanes;
    for (final lane in lanes) {
      final target = showLanes && lane._present ? 1.0 : 0.0;
      lane.amount += (target - lane.amount) * (1 - exp(-3 * dt));
      lane._present = false;
    }

    // The stars are far away, they only follow the camera a bit
    final shake = hit * hit * 7;
    shakeX = kickX * 0.6 + sin(_hitTime * 57) * shake;
    shakeY = kickY * 0.6 + cos(_hitTime * 43) * shake;

    final glowBlend = 1 - exp(-4 * dt);
    glowR += (_glowTarget.r - glowR) * glowBlend;
    glowG += (_glowTarget.g - glowG) * glowBlend;
    glowB += (_glowTarget.b - glowB) * glowBlend;

    if (wasActive || _isActive) {
      notifyListeners();
    }
  }
}

/// Ways the background shows that a wave of multiple orbs is coming
enum TenseStyle {
  /// The stars fly faster and a few long streaks glide out past them
  rush,

  /// The stars turn around and stream in towards the potato, like the orbs
  inward,

  /// The calm before the storm: the stars slow down and dim when the wave is
  /// announced, then rush out when its orbs start flying
  hush,

  /// A faint glow along the lanes the wave's orbs fly in on
  lanes,
}

/// A faint glow along the lane a wave's orbs fly in on
class BackgroundLane {
  double dirX = 1, dirY = 0;
  double r = 1, g = 1, b = 1;

  /// From 0 to 1, fades in and out with the wave
  double amount = 0;

  bool _present = false;
}

/// A shockwave rolling out of the potato through the stars
class BackgroundWave {
  double age = 0;
  double lifespan = 0;
  double fromRadius = 0;
  double toRadius = 0;
  double peak = 0;

  /// Direction it is strongest in, and how much stronger (0 is a full ring)
  double dirX = 1, dirY = 0;
  double focus = 0;

  double r = 1, g = 1, b = 1;

  bool get isActive => age < lifespan;

  double get progress => lifespan <= 0 ? 1 : min(1.0, age / lifespan);

  /// Radius in world units, races out and slows down
  double get radius {
    final t = 1 - progress;
    return lerpDouble(fromRadius, toRadius, 1 - t * t * t)!;
  }

  /// Half the width of its ring, in world units, it widens as it grows
  double get halfWidth => 2 * (14 + radius * 0.1);

  double get intensity {
    if (!isActive) {
      return 0;
    }
    final t = 1 - progress;
    // A quick fade in, so it doesn't pop
    final fadeIn = min(1.0, age / 0.05);
    return peak * t * sqrt(t) * fadeIn;
  }
}
