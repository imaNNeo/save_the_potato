import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/hit_invincibility.dart';
import 'package:save_the_potato/presentation/components/hit_blink.dart';
import 'package:save_the_potato/presentation/components/guide_title.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato/potato_animator.dart';
import 'package:save_the_potato/presentation/potato/potato_face_component.dart';
import 'package:save_the_potato/presentation/potato/potato_health_prototypes.dart';
import 'package:save_the_potato/service_locator.dart';

import '../potato_game.dart';
import 'moving/moving_components.dart';
import 'moving/orb/orb_type.dart';

class Potato extends PositionComponent
    with
        HasGameReference<PotatoGame>,
        CollisionCallbacks,
        FlameBlocListenable<GameCubit, GameState>,
        ParentIsA<MyWorld> {
  Potato({double size = 100})
    : super(
        size: Vector2.all(size),
        position: Vector2.all(0),
        anchor: Anchor.center,
      );

  late final Shield fireShield;
  late final Shield iceShield;

  double get radius => size.x / 2;

  /// Plays the potato's face animations (hit, scared, amazed, die, ...).
  final face = PotatoAnimator();

  final _audioHelper = getIt.get<AudioHelper>();
  GameState? _lastState;

  /// After a hit, the potato blinks and orbs can't hurt it for a moment
  final invincibility = HitInvincibility();

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState ||
      previousState.currentGameMode.runtimeType !=
          newState.currentGameMode.runtimeType ||
      previousState.playMotivationWord != newState.playMotivationWord;

  @override
  void onNewState(GameState state) {
    if (_lastState?.playingState != state.playingState) {
      // A new run or the end of one, nothing to protect anymore
      invincibility.reset();
    }
    if (_lastState?.playingState != state.playingState &&
        state.playingState is PlayingStateGameOver) {
      face.die();
    }
    if (_lastState?.currentGameMode.runtimeType !=
        state.currentGameMode.runtimeType) {
      // GameMode is changed
      switch (state.currentGameMode) {
        case GameModeSingleSpawn():
          if (state.gameModeHistory.isEmpty) {
            face.calmDown();
            return;
          }
          final previousMode = state.gameModeHistory.last as GameModeMultiSpawn;
          if (!previousMode.shouldPlayMotivationWord()) {
            face.calmDown();
          }
        case GameModeMultiSpawn():
          face.scared();
      }
    }
    if (state.playMotivationWord != null) {
      face.amazed();
    }
    _lastState = state;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(
      CircleHitbox(
        collisionType: CollisionType.active,
        radius: radius * 0.7,
        position: size / 2,
        anchor: Anchor.center,
      ),
    );

    add(
      HitBlink(invincibility: invincibility, size: size, position: size / 2)
        ..add(PotatoFaceComponent(animator: face, position: size / 2))
        ..addAll([
          if (PotatoHealthStyle.current != null)
            PotatoHealthOverlay(
              style: PotatoHealthStyle.current!,
              position: size / 2,
            ),
        ]),
    );
    add(fireShield = Shield(type: OrbType.fire));
    add(iceShield = Shield(type: OrbType.ice));

    if (game.playingState.isGuide) {
      add(GuideTitle());
    }

    mounted.then((_) {
      _lastState = bloc.state;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    invincibility.update(dt);
    if (bloc.state.playingState.isPlaying) {
      final rotationSpeed = bloc.state.shieldsAngleRotationSpeed;
      if (rotationSpeed != 0) {
        fireShield.angle += rotationSpeed * dt;
      }
    }
    iceShield.angle = fireShield.angle - pi;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is MovingComponent) {
      switch (other) {
        case MovingHealth():
          getIt.get<AnalyticsHelper>().heartReceived();
          _audioHelper.playHeartHitSound();
          game.onHealthPointReceived();
          face.heartHit();
          other.onConsumed();
          break;
        case FireOrb() when other.rhythmHit?.companion ?? false:
          // Only there to fill the chord, its melody orb already counts
          other.onPotatoHit();
          break;
        case FireOrb() when invincibility.isActive:
          // Still recovering from the last hit, it does no damage
          other.onPotatoHit();
          break;
        case FireOrb():
          _onOrbHit(other);
          if (bloc.state.life > 0) {
            face.fireHit();
          }
          other.onPotatoHit();
          break;
        case IceOrb() when other.rhythmHit?.companion ?? false:
          // Only there to fill the chord, its melody orb already counts
          other.onPotatoHit();
          break;
        case IceOrb() when invincibility.isActive:
          // Still recovering from the last hit, it does no damage
          other.onPotatoHit();
          break;
        case IceOrb():
          _onOrbHit(other);
          if (bloc.state.life > 0) {
            face.iceHit();
          }
          other.onPotatoHit();
          break;
      }
      other.removeFromParent();
    }
  }

  void _onOrbHit(PositionComponent orb) {
    _audioHelper.playOrbHitSound();
    game.onOrbHit(_angleTo(orb));
    if (bloc.state.life > 0 && bloc.state.playingState.isPlaying) {
      invincibility.trigger();
    }
  }

  double _angleTo(PositionComponent other) {
    final diff = other.absoluteCenter - absoluteCenter;
    return atan2(diff.y, diff.x);
  }
}
