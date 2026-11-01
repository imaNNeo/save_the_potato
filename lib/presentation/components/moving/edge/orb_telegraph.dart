import 'package:flame/components.dart';

/// Whatever shows the player where the next orb comes from: a portal, a
/// rift in the arena ring, a crawler on the rim or a ripple.
abstract interface class OrbTelegraph {
  /// Where the orb leaves from, in world space (the potato is at 0, 0)
  Vector2 get spawnPoint;

  /// The orb has left, let the telegraph finish and go away
  void close();
}
