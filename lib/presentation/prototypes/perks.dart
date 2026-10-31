import 'package:flutter/material.dart';

import 'prototypes.dart';

/// Prototype 2: a roguelite run. Every [PerkRun.draftEvery] seconds the game
/// stops and offers three perks, drawn as icons only. Perks stack and only
/// last for the current run.
enum Perk {
  wideShields(Icons.open_in_full_rounded, Color(0xFFFFB13D)),
  extraHeart(Icons.favorite_rounded, Color(0xFFFF2E6B)),
  slowOrbs(Icons.hourglass_bottom_rounded, Color(0xFF7FD4FF)),
  quickTurn(Icons.sync_rounded, Color(0xFF9CFF6B)),
  streakHeal(Icons.healing_rounded, Color(0xFFFF7EC8)),
  luckyHearts(Icons.volunteer_activism_rounded, Color(0xFFFFE066));

  const Perk(this.icon, this.color);

  final IconData icon;
  final Color color;
}

class PerkRun extends ChangeNotifier {
  PerkRun._();

  static final instance = PerkRun._();

  static double get draftEvery => Prototypes.number('draftEvery') ?? 25.0;

  final picked = <Perk>[];

  /// The three perks on offer, empty when there is no draft open
  List<Perk> offer = const [];

  double nextDraftAt = draftEvery;

  int count(Perk perk) => picked.where((p) => p == perk).length;

  int get extraHearts => count(Perk.extraHeart);

  double get orbSpeedScale => 1.0 - 0.12 * count(Perk.slowOrbs);

  double get turnSpeedScale => 1.0 + 0.25 * count(Perk.quickTurn);

  double get shieldSweepScale => 1.0 + 0.3 * count(Perk.wideShields);

  /// Heal one heart after this many blocks in a row
  int? get streakHealEvery =>
      count(Perk.streakHeal) == 0 ? null : 20 ~/ count(Perk.streakHeal);

  double get heartChanceScale => 1.0 + 2.0 * count(Perk.luckyHearts);

  void reset() {
    picked.clear();
    offer = const [];
    nextDraftAt = draftEvery;
    notifyListeners();
  }

  /// Opens a draft once the run passes [nextDraftAt]
  bool shouldOpenDraft(double levelTime) =>
      offer.isEmpty && levelTime >= nextDraftAt;

  void openDraft() {
    final pool = [...Perk.values]..shuffle(ProtoHooks.rnd);
    offer = pool.take(3).toList();
    notifyListeners();
  }

  void pick(Perk perk) {
    picked.add(perk);
    offer = const [];
    nextDraftAt += draftEvery;
    notifyListeners();
  }
}
