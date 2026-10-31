import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart' show Colors, Curves;
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

/// An empty heart that fills up a bit with every orb blocked in a row while a
/// heart is missing. When it is full the potato gets the heart back, getting
/// hit empties it. See [GameState.heartCharge].
///
/// It sits right above the potato, and only shows while a heart is missing.
class HeartCharge extends PositionComponent
    with
        HasGameReference<PotatoGame>,
        FlameBlocListenable<GameCubit, GameState> {
  HeartCharge() : super(anchor: Anchor.center, priority: -1);

  /// How big the heart is, in world units
  static const heartSize = 36.0;

  /// How far above the potato's center the heart sits
  static const distanceFromPotato = 112.0;

  static const _earnDuration = 0.7;

  late final Sprite _filled;
  late final Sprite _outline;

  final _fillPaint = Paint();
  final _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final _outlinePaint = Paint();
  final _pipPaint = Paint();

  int _healthPoints = GameConstants.maxHealthPoints;
  int _charge = 0;

  /// How much of the heart is drawn filled, follows [_charge] smoothly
  double _fill = 0;

  /// How much the heart shows, from 0 to 1
  double _opacity = 0;

  /// Jumps up on every block, makes the heart beat
  double _pulse = 0;

  /// Jumps up when the streak is lost, makes the heart shake and grey out
  double _lost = 0;

  /// Counts from 0 to 1 after a heart is earned, -1 when not earning
  double _earned = -1;

  double _time = 0;

  bool get _wantsToShow =>
      bloc.state.playingState.isPlaying &&
      _healthPoints < GameConstants.maxHealthPoints;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _filled = await Sprite.load('heart/heart1.png');
    _outline = await Sprite.load('heart/heart2.png');
    size = Vector2.all(heartSize);
    position = Vector2(0, -distanceFromPotato);
  }

  @override
  void onInitialState(GameState state) {
    super.onInitialState(state);
    _healthPoints = state.healthPoints;
    _charge = state.heartCharge;
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.healthPoints != newState.healthPoints ||
      previousState.heartCharge != newState.heartCharge;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (state.healthPoints > _healthPoints) {
      _onHeartEarned();
    } else if (state.heartCharge > _charge) {
      _pulse = 1;
    } else if (state.heartCharge < _charge) {
      _lost = 1;
    }
    _healthPoints = state.healthPoints;
    _charge = state.heartCharge;
  }

  void _onHeartEarned() {
    _earned = 0;
    _fill = 1;
    _pulse = 1;
    game.background.healed();
    game.world.player.heartHitTrigger.fire();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pulse *= exp(-6 * dt);
    _lost *= exp(-3 * dt);

    if (_earned >= 0) {
      _earned += dt / _earnDuration;
      if (_earned >= 1) {
        // The new heart flew off, start over empty
        _earned = -1;
        _fill = 0;
        _opacity = 0;
      }
      return;
    }

    final targetFill = _charge / GameConstants.blocksToEarnHeart;
    // Fills up quickly, drains a bit slower so the loss reads
    final rate = targetFill > _fill ? 14.0 : 5.0;
    _fill += (targetFill - _fill) * (1 - exp(-rate * dt));

    final targetOpacity = _wantsToShow ? 1.0 : 0.0;
    _opacity += (targetOpacity - _opacity) * (1 - exp(-6 * dt));
  }

  @override
  void render(Canvas canvas) {
    var opacity = _opacity;
    var scale = 1 + _pulse * 0.22;
    var dx = 0.0;
    if (_earned >= 0) {
      // Pops up and fades out
      final t = _earned;
      scale = 1 + Curves.easeOutBack.transform(t) * 0.9;
      opacity = 1 - t * t;
    } else {
      // A gentle heartbeat, faster the fuller it is
      scale += sin(_time * (3 + _fill * 5)) * 0.03 * (0.4 + _fill);
      dx = sin(_time * 60) * _lost * 3;
    }
    if (opacity <= 0.01) {
      return;
    }

    canvas.save();
    canvas.translate(size.x / 2 + dx, size.y / 2);
    canvas.scale(scale);
    canvas.translate(-size.x / 2, -size.y / 2);

    final pink = GameColors.healthPointColor;
    final grey = Color.lerp(pink, Colors.grey, _lost)!;

    // The glow grows as the heart fills
    if (_fill > 0.01) {
      _glowPaint.colorFilter = ColorFilter.mode(
        grey.withValues(alpha: opacity * (0.25 + 0.55 * _fill)),
        BlendMode.srcIn,
      );
      _filled.render(
        canvas,
        size: size * 1.25,
        anchor: Anchor.center,
        position: size / 2,
        overridePaint: _glowPaint,
      );
    }

    // The empty heart, faint
    _fillPaint.colorFilter = ColorFilter.mode(
      Colors.white.withValues(alpha: opacity * 0.08),
      BlendMode.srcIn,
    );
    _filled.render(canvas, size: size, overridePaint: _fillPaint);

    // Filled from the bottom up
    if (_fill > 0.001) {
      canvas.save();
      final top = size.y * (0.92 - 0.86 * _fill);
      canvas.clipRect(Rect.fromLTRB(0, top, size.x, size.y));
      _fillPaint.colorFilter = ColorFilter.mode(
        grey.withValues(alpha: opacity),
        BlendMode.srcIn,
      );
      _filled.render(canvas, size: size, overridePaint: _fillPaint);
      canvas.restore();
    }

    _outlinePaint.colorFilter = ColorFilter.mode(
      Colors.white.withValues(alpha: opacity * 0.9),
      BlendMode.srcIn,
    );
    _outline.render(
      canvas,
      size: size * 1.2,
      anchor: Anchor.center,
      position: size / 2,
      overridePaint: _outlinePaint,
    );
    canvas.restore();

    if (_earned < 0) {
      _renderPips(canvas, opacity, grey);
    }
  }

  /// One dot per block needed, lit for the ones done
  void _renderPips(Canvas canvas, double opacity, Color color) {
    const count = GameConstants.blocksToEarnHeart;
    const gap = 8.0;
    const radius = 2.2;
    final y = size.y + 9;
    final startX = size.x / 2 - (count - 1) * gap / 2;
    for (var i = 0; i < count; i++) {
      final lit = i < _charge;
      _pipPaint.color = lit
          ? color.withValues(alpha: opacity)
          : Colors.white.withValues(alpha: opacity * 0.25);
      canvas.drawCircle(
        Offset(startX + i * gap, y),
        lit ? radius * 1.2 : radius,
        _pipPaint,
      );
    }
  }
}
