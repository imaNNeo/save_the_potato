import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';

/// Prototype 1: unlockable shield themes.
///
/// Every second you survive earns a spark. Sparks unlock new color pairs for
/// the shields and orbs, and a matching sky.
class ShieldTheme {
  const ShieldTheme({
    required this.fire,
    required this.ice,
    required this.sky,
    required this.cost,
  });

  /// Light, base and intense colors, like [GameConstants.redColors]
  final List<Color> fire;
  final List<Color> ice;

  /// The background color behind the stars
  final Color sky;

  /// Sparks needed to unlock it
  final int cost;

  List<Color> colorsFor(OrbType type) => switch (type) {
    OrbType.fire => fire,
    OrbType.ice => ice,
  };
}

class ShieldThemes {
  static const all = [
    ShieldTheme(
      fire: GameConstants.redColors,
      ice: GameConstants.blueColors,
      sky: Color(0xFF00004D),
      cost: 0,
    ),
    // Toxic: acid green against violet
    ShieldTheme(
      fire: [Color(0xFFD9FF8A), Color(0xFF8CFF2E), Color(0xFF3FD400)],
      ice: [Color(0xFFE6C2FF), Color(0xFFB45CFF), Color(0xFF7A1FFF)],
      sky: Color(0xFF0F1A06),
      cost: 60,
    ),
    // Solar: gold against magenta
    ShieldTheme(
      fire: [Color(0xFFFFF0A8), Color(0xFFFFC400), Color(0xFFFF9500)],
      ice: [Color(0xFFFFC2EC), Color(0xFFFF4FC8), Color(0xFFD6009A)],
      sky: Color(0xFF2A0A1E),
      cost: 150,
    ),
    // Neon: hot pink against cyan
    ShieldTheme(
      fire: [Color(0xFFFFB3D9), Color(0xFFFF2E93), Color(0xFFE6006B)],
      ice: [Color(0xFFB8FFF6), Color(0xFF22F2D8), Color(0xFF00BFA8)],
      sky: Color(0xFF06061A),
      cost: 300,
    ),
    // Royal: white gold against deep sapphire
    ShieldTheme(
      fire: [Color(0xFFFFFFFF), Color(0xFFFFE9B0), Color(0xFFE8C46A)],
      ice: [Color(0xFF9FB8FF), Color(0xFF3D63FF), Color(0xFF1F3BD6)],
      sky: Color(0xFF120A2A),
      cost: 600,
    ),
  ];

  static int selectedIndex = 0;

  /// Sparks earned so far, a prototype keeps them in memory only
  static int sparks = 140;

  static ShieldTheme get selected => all[selectedIndex];

  static bool isUnlocked(int index) => _unlocked.contains(index);

  static final Set<int> _unlocked = {0, 1};

  /// Spends the sparks and unlocks [index] if there are enough
  static bool tryUnlock(int index) {
    if (isUnlocked(index)) {
      return true;
    }
    final cost = all[index].cost;
    if (sparks < cost) {
      return false;
    }
    sparks -= cost;
    _unlocked.add(index);
    return true;
  }
}
