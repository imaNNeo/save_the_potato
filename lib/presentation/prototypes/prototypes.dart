import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';

import 'perks.dart';
import 'themes.dart';

/// Play time prototypes. Each one is switched on alone, so they can be judged
/// one by one without touching the normal game:
/// - web: `?proto=themes` (add `&bot=1` for the autopilot used in the videos)
/// - other platforms: `--dart-define=PROTO=themes` (and `BOT=true`)
enum Prototype { none, themes, perks, levels, missions, coop, boss }

class Prototypes {
  static final Prototype active = _readActive();

  /// Plays the game by itself, used to record the gameplay videos
  static final bool autopilot =
      _param('bot') == '1' || const bool.fromEnvironment('BOT');

  static bool get isOn => active != Prototype.none;

  static bool get themes => active == Prototype.themes;

  static bool get perks => active == Prototype.perks;

  static bool get levels => active == Prototype.levels;

  static bool get missions => active == Prototype.missions;

  static bool get coop => active == Prototype.coop;

  static bool get boss => active == Prototype.boss;

  static String? _param(String key) =>
      kIsWeb ? Uri.base.queryParameters[key] : null;

  /// A number from the url, for tuning the prototypes while recording
  static double? number(String key) => double.tryParse(_param(key) ?? '');

  static Prototype _readActive() {
    final name = _param('proto') ?? const String.fromEnvironment('PROTO');
    return Prototype.values.firstWhere(
      (p) => p.name == name,
      orElse: () => Prototype.none,
    );
  }
}

/// Small knobs the game reads, so every prototype only needs a few hooks in
/// the real code. They all return the normal game's values when no
/// prototype is on.
class ProtoHooks {
  static List<Color>? colorsFor(OrbType type) =>
      Prototypes.themes ? ShieldThemes.selected.colorsFor(type) : null;

  static int get maxHealthPoints =>
      GameConstants.maxHealthPoints +
      (Prototypes.perks ? PerkRun.instance.extraHearts : 0);

  static double get orbSpeedScale =>
      Prototypes.perks ? PerkRun.instance.orbSpeedScale : 1.0;

  static double get turnSpeedScale =>
      Prototypes.perks ? PerkRun.instance.turnSpeedScale : 1.0;

  static double get shieldSweepScale =>
      Prototypes.perks ? PerkRun.instance.shieldSweepScale : 1.0;

  /// Co-op: the ice shield turns by itself, at this speed
  static double iceShieldSpeed = 0;

  /// A prototype panel stopped the game, so the pause menu stays hidden
  static bool frozen = false;

  static double get heartChanceScale =>
      Prototypes.perks ? PerkRun.instance.heartChanceScale : 1.0;

  /// Co-op has two players, so it throws a second orb more often
  static double get extraOrbChance => Prototypes.coop ? 0.55 : 0.0;

  static Color skyFor(int modeIndex, Color normal) =>
      Prototypes.themes && modeIndex == 0 ? ShieldThemes.selected.sky : normal;

  /// The boss stops the normal spawner while it fights
  static bool pauseNormalSpawns = false;

  static final Random rnd = Random();
}
