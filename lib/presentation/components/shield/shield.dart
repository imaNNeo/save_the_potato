import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/components/shield/ui/shield_ui1.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

import '../moving/moving_components.dart';
import '../moving/orb/orb_type.dart';
import 'ui/shield_ui3.dart';

class Shield extends PositionComponent
    with
        ParentIsA<Potato>,
        HasGameRef<PotatoGame>,
        CollisionCallbacks,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  Shield({
    required this.type,
    this.shieldWidth = 6.0,
    this.shieldSweep = pi / 2,
    this.offset = 12,
  }) : super(
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  final OrbType type;
  final double shieldWidth;
  final double shieldSweep;
  final double offset;

  final _audioHelper = getIt.get<AudioHelper>();

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    timeScale = state.gameOverTimeScale;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = parent.size + Vector2.all(shieldWidth * 2) + Vector2.all(offset * 2);
    position = parent.size / 2;
    _addHitbox();
    if (type == OrbType.fire) {
      add(ShieldUiStyle3());
    }
  }

  void _addHitbox() {
    final center = size / 2;

    const precision = 8;

    final segment = shieldSweep / (precision - 1);
    final radius = size.x / 2;
    final startAngle = 0 - shieldSweep / 2;

    List<Vector2> vertices = [];
    for (int i = 0; i < precision; i++) {
      final thisSegment = startAngle + segment * i;
      vertices.add(
        center + Vector2(cos(thisSegment), sin(thisSegment)) * radius,
      );
    }

    for (int i = precision - 1; i >= 0; i--) {
      final thisSegment = startAngle + segment * i;
      vertices.add(
        center +
            Vector2(cos(thisSegment), sin(thisSegment)) *
                (radius - shieldWidth),
      );
    }

    add(PolygonHitbox(
      vertices,
      collisionType: CollisionType.active,
    ));
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is MovingComponent) {
      switch (other) {
        case MovingHealth():
          bloc.onShieldHit(other);
          _audioHelper.playShieldSound(bloc.state.shieldHitCounter);
          other.disjoint();
        case FireOrb():
        case IceOrb():
          final orb = other as MovingOrb;
          if ((orb.type.isFire && type.isFire) ||
              (orb.type.isIce && type.isIce)) {
            bloc.onShieldHit(other);
            if (orb.overrideCollisionSoundNumber != null) {
              _audioHelper.playShieldSound(orb.overrideCollisionSoundNumber!);
            } else {
              _audioHelper.playShieldSound(bloc.state.shieldHitCounter);
            }
            final orbPos = other.absolutePosition;
            final diff = orbPos - absolutePosition;
            final contactAngle = atan2(diff.y, diff.x);
            other.disjoint(contactAngle);
          }
      }
    }
  }
}
