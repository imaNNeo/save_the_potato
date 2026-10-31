import 'dart:math';

import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'prototypes.dart';

/// Prototype 5: two players on one phone, laid flat between them. The
/// bottom player turns the fire shield, the top player (who sees the screen
/// upside down) turns the ice shield. On a keyboard: A/D and the arrows.
class CoopControls extends StatefulWidget {
  const CoopControls({super.key, required this.cubit, required this.showGuide});

  final GameCubit cubit;
  final bool showGuide;

  @override
  State<CoopControls> createState() => _CoopControlsState();
}

class _CoopControlsState extends State<CoopControls> {
  static const _maxSpeed = pi * 1.8;

  /// -1, 0 or 1 for each side of each player
  final _fire = <int, double>{};
  final _ice = <int, double>{};

  void _update() {
    double sum(Map<int, double> m) =>
        m.values.fold(0.0, (a, b) => a + b).clamp(-1.0, 1.0);
    widget.cubit.steer(sum(_fire));
    ProtoHooks.iceShieldSpeed = sum(_ice) * _maxSpeed;
  }

  Widget _button({
    required bool fire,
    required double dir,
    required Color color,
  }) {
    final map = fire ? _fire : _ice;
    return Expanded(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          map[e.pointer] = dir;
          widget.cubit.startFromGuide();
          _update();
        },
        onPointerUp: (e) {
          map.remove(e.pointer);
          _update();
        },
        onPointerCancel: (e) {
          map.remove(e.pointer);
          _update();
        },
        child: Align(
          alignment: dir < 0 ? Alignment.bottomLeft : Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 36, 56),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: widget.showGuide ? 1 : 0.35,
              child: Icon(
                dir < 0 ? Icons.undo_rounded : Icons.redo_rounded,
                size: widget.showGuide ? 72 : 48,
                color: color,
                shadows: [Shadow(color: color, blurRadius: 16)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _player({required bool fire}) {
    final color = fire
        ? GameConstants.redColors[1]
        : GameConstants.blueColors[1];
    return Row(
      children: [
        _button(fire: fire, dir: -1, color: color),
        _button(fire: fire, dir: 1, color: color),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(quarterTurns: 2, child: _player(fire: false)),
        ),
        Expanded(child: _player(fire: true)),
      ],
    );
  }
}
