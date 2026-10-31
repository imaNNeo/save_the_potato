import 'package:flame/components.dart' hide ComponentPool;
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_hit.dart';

import 'moving_components.dart';
import 'orb/orb_type.dart';

class MovingComponentSpawner extends Component
    with ParentIsA<MyWorld>, FlameBlocListenable<GameCubit, GameState> {
  // Spawns the orbs; the rhythm director decides when

  Potato get player => parent.player;

  PotatoGame get game => parent.game;

  late ComponentPool<FireOrb> _fireOrbPool;
  late ComponentPool<IceOrb> _iceOrbPool;

  @override
  void onLoad() {
    super.onLoad();
    _fireOrbPool = ComponentPool<FireOrb>(
      () => FireOrb(),
      initialSize: 10,
      debugName: 'FireOrbPool',
    );
    _iceOrbPool = ComponentPool<IceOrb>(
      () => IceOrb(),
      initialSize: 10,
      debugName: 'IceOrbPool',
    );
  }

  /// How far from the potato orbs spawn
  double get spawnDistance => (game.size.x / 2) + (game.size.x * 0.05);

  /// Spawns one orb for the rhythm director
  void spawnRhythmOrb({
    required OrbType type,
    required Vector2 position,
    required double speed,
    RhythmHit? rhythmHit,
  }) {
    late MovingOrb orb;
    switch (type) {
      case OrbType.fire:
        orb = _fireOrbPool.get();
      case OrbType.ice:
        orb = _iceOrbPool.get();
    }
    orb.loaded.then((_) {
      orb.initialize(
        speed: speed,
        target: player,
        position: position,
        onDisjointCallback: () => _release(orb),
        onPotatoHitCallback: () => _release(orb),
      );
      orb.rhythmHit = rhythmHit;
    });
    parent.add(orb);
  }

  void _release(MovingOrb orb) {
    switch (orb) {
      case FireOrb():
        _fireOrbPool.release(orb);
      case IceOrb():
        _iceOrbPool.release(orb);
    }
  }
}
