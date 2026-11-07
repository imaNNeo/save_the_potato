import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/hit_invincibility.dart';
import 'package:save_the_potato/domain/potato_vibe.dart';
import 'package:save_the_potato/presentation/components/hit_blink.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato/potato_animator.dart';
import 'package:save_the_potato/presentation/potato/potato_face_component.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';
import 'package:save_the_potato/presentation/potato/potato_vibe_motion.dart';
import 'package:save_the_potato/presentation/potato/music_notes.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_hit.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';
import 'package:save_the_potato/presentation/potato/dizzy_face.dart';
import 'package:save_the_potato/presentation/potato/potato_health_motion.dart';
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

  /// How much the potato enjoys the music the shields play, and how shaken
  /// it is by orbs that get through
  final vibe = PotatoVibe();
  late final _vibeMotion = PotatoVibeMotion(vibe);

  /// Shows the life left on the potato's face and body
  final healthMotion = PotatoHealthMotion();
  late final MusicNotes _musicNotes;

  static const _artboardToLocal = 0.0032;

  int _lastNoteBeat = -1;

  /// Keeps the beat when there's no song clock (menu, muted before a run)
  double _ownBeatTime = 0;

  /// The dizzy face it makes while it recovers from a hit
  final dizzy = DizzyFace();

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState ||
      previousState.currentGameMode.runtimeType !=
          newState.currentGameMode.runtimeType ||
      previousState.playMotivationWord != newState.playMotivationWord ||
      previousState.level != newState.level;

  @override
  void onNewState(GameState state) {
    if (_lastState?.playingState != state.playingState) {
      // A new run or the end of one, nothing to protect anymore
      invincibility.reset();
      final wasInRun =
          _lastState?.playingState.isPlaying == true ||
          _lastState?.playingState.isPaused == true;
      if (state.playingState.isPlaying && !wasInRun) {
        vibe.reset();
        healthMotion.reset();
        _musicNotes.clear();
      }
      dizzy.reset();
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
    if (_lastState != null &&
        _lastState!.level != state.level &&
        state.playingState.isGuide) {
      // A mode or level was picked on the home screen
      final level = state.level;
      if (level != null && !Levels.isOpen(level, state.levelsCleared)) {
        face.scared();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (isMounted) {
            face.calmDown();
          }
        });
      } else {
        face.amazed();
      }
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
        ..add(
          PotatoFaceComponent(animator: face, dizzy: dizzy, position: size / 2),
        ),
    );
    add(
      _musicNotes = MusicNotes(
        size: size,
        priority: 1,
        // The painter's 500 wide artboard is about 1.6 times the potato
        bodyOffset: () => Offset(
          face.pose[PotatoProp.bodyX] * size.x * _artboardToLocal,
          face.pose[PotatoProp.bodyY] * size.x * _artboardToLocal,
        ),
      ),
    );
    add(fireShield = Shield(type: OrbType.fire));
    add(iceShield = Shield(type: OrbType.ice));

    if (game.playingState.isGuide) {
      // The level select shows the title on the home screen
      // It arrives from the splash with its headphones on
      _vibeMotion.wearHeadphones();
    }

    mounted.then((_) {
      _lastState = bloc.state;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    invincibility.update(dt);
    _updateVibe(dt);
    if (bloc.state.playingState.isPlaying) {
      fireShield.angle +=
          bloc.state.shieldsTurnDirection * GameConstants.shieldsTurnSpeed * dt;
    } else if (bloc.state.playingState.isGuide) {
      // On the home screen the fire shield points up at the picked level
      const target = -pi / 2;
      final delta = atan2(
        sin(target - fireShield.angle),
        cos(target - fireShield.angle),
      );
      fireShield.angle += delta * min(1.0, dt * 8);
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
    final angle = _angleTo(orb);
    game.onOrbHit(angle);
    if (bloc.state.life > 0 &&
        bloc.state.playingState.isPlaying &&
        !bloc.state.tutorial) {
      invincibility.trigger();
      dizzy.trigger();
    }
    vibe.onHit();
    // Knocked away from the side the orb came from
    _vibeMotion.knock(cos(angle) < 0 ? 1 : -1);
  }

  /// A blocked orb played a melody note: the potato enjoys it
  void onNotePlayed(RhythmHit hit) {
    if (!bloc.state.playingState.isPlaying) {
      return;
    }
    vibe.onNote();
  }

  void _updateVibe(double dt) {
    final state = bloc.state;
    final playing = state.playingState.isPlaying;
    if (state.playingState.isPaused) {
      return;
    }
    vibe.update(dt, life: state.life, playing: playing);
    _ownBeatTime += dt;
    final rhythm = parent.isLoaded ? parent.rhythm : null;
    final songTime = rhythm != null && rhythm.isRunning
        ? rhythm.songTime
        : _ownBeatTime;
    _updateBeatNotes(songTime, state.song.beatSeconds, playing: playing);
    _vibeMotion.update(
      dt,
      face.pose,
      songTime: songTime,
      beatSeconds: state.song.beatSeconds,
      // On from the start screen, so it's ready for the music
      headphonesOn: playing || state.playingState.isGuide,
      faceFree: face.mood == PotatoMood.idle,
    );
    healthMotion.update(
      dt,
      face.pose,
      life: state.life,
      playing: playing && !state.tutorial,
      faceFree: face.mood == PotatoMood.idle,
    );
  }

  /// Notes come out of the headphones on the beat of the song while the
  /// potato is calm and lost in the music, whether or not orbs are blocked.
  /// They stop while it's shaken by a hit.
  void _updateBeatNotes(
    double songTime,
    double beatSeconds, {
    required bool playing,
  }) {
    final beat = (songTime / beatSeconds).floor();
    if (beat == _lastNoteBeat) return;
    _lastNoteBeat = beat;
    if (!playing) return;
    final shaken = invincibility.isActive ? 0.0 : 1 - vibe.nerves;
    _musicNotes.onBeat(beat, flow: healthMotion.calm * shaken);
  }

  double _angleTo(PositionComponent other) {
    final diff = other.absoluteCenter - absoluteCenter;
    return atan2(diff.y, diff.x);
  }
}
