import 'package:flutter/material.dart';

/// Prototype 4: three missions at a time, which carry over between runs.
/// Finishing one gives XP, XP levels up the potato, and a finished mission is
/// replaced by a new, slightly harder one.
enum MissionKind {
  blockFire(Icons.local_fire_department_rounded, Color(0xFFFF5900)),
  blockIce(Icons.ac_unit_rounded, Color(0xFF00AFFF)),
  survive(Icons.timer_rounded, Color(0xFFFFFFFF)),
  streak(Icons.bolt_rounded, Color(0xFFFFD84D)),
  hearts(Icons.favorite_rounded, Color(0xFFFF2E6B)),
  flawlessWave(Icons.shield_rounded, Color(0xFFB98CFF));

  const MissionKind(this.icon, this.color);

  final IconData icon;
  final Color color;

  /// Survive and streak are the best of a single run, the rest add up
  bool get isBestOfRun => this == survive || this == streak;
}

class Mission {
  Mission(this.kind, this.goal);

  final MissionKind kind;
  final int goal;
  int progress = 0;

  bool get done => progress >= goal;

  double get ratio => (progress / goal).clamp(0.0, 1.0);

  int get xp => 40 + goal;
}

class Missions extends ChangeNotifier {
  Missions._();

  static final instance = Missions._();

  static const xpPerLevel = 120;

  final active = <Mission>[
    Mission(MissionKind.blockFire, 8),
    Mission(MissionKind.survive, 20),
    Mission(MissionKind.streak, 6),
  ];

  int xp = 0;
  int potatoLevel = 1;

  /// Missions finished in the current run, shown on the game over screen
  final finishedThisRun = <Mission>[];

  /// The last mission finished, for the pop up while playing
  Mission? justFinished;

  int _tier = 1;

  double get levelRatio => xp / xpPerLevel;

  void startRun() {
    finishedThisRun.clear();
    for (final m in active) {
      if (m.kind.isBestOfRun) {
        m.progress = 0;
      }
    }
    notifyListeners();
  }

  void add(MissionKind kind, [int amount = 1]) => _update(kind, (m) {
    m.progress += amount;
  });

  void best(MissionKind kind, int value) => _update(kind, (m) {
    if (value > m.progress) {
      m.progress = value;
    }
  });

  void _update(MissionKind kind, void Function(Mission) change) {
    var changed = false;
    for (final m in active) {
      if (m.kind != kind || m.done) {
        continue;
      }
      final before = m.progress;
      change(m);
      if (m.progress == before) {
        continue;
      }
      changed = true;
      if (m.done) {
        finishedThisRun.add(m);
        justFinished = m;
        xp += m.xp;
        while (xp >= xpPerLevel) {
          xp -= xpPerLevel;
          potatoLevel++;
        }
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Swaps finished missions for new ones, called on the menu
  void refill() {
    var changed = false;
    for (var i = 0; i < active.length; i++) {
      if (!active[i].done) {
        continue;
      }
      _tier++;
      active[i] = _next(i);
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  Mission _next(int slot) {
    final used = active.map((m) => m.kind).toSet();
    final kinds = MissionKind.values.where((k) => !used.contains(k)).toList();
    final kind = kinds[(slot + _tier) % kinds.length];
    final goal = switch (kind) {
      MissionKind.blockFire || MissionKind.blockIce => 10 + 5 * _tier,
      MissionKind.survive => 20 + 10 * _tier,
      MissionKind.streak => 8 + 2 * _tier,
      MissionKind.hearts => 1 + _tier ~/ 3,
      MissionKind.flawlessWave => 1 + _tier ~/ 4,
    };
    return Mission(kind, goal);
  }
}
