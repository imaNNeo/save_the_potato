import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:save_the_potato/presentation/components/shield/shield.dart';

class ShieldUiStyle2 extends PositionComponent with ParentIsA<Shield> {
  final List<RiveComponent> _shieldRives = [];

  final int _shieldCount = 1;

  @override
  void onLoad() async {
    super.onLoad();
    size = parent.size;
    final type = parent.type;
    final shieldArtboard = await loadArtboard(
      RiveFile.asset('assets/rive/shield.riv'),
    );

    final controller = StateMachineController.fromArtboard(
      shieldArtboard,
      "State Machine 1",
    )!;
    shieldArtboard.addController(controller);

    for (int i = 0; i < _shieldCount; i++) {
      Future.delayed(Duration(milliseconds: 70 * i)).then((_) {
        if (isRemoved || isRemoving) {
          return;
        }
        final newComponent = RiveComponent(
          artboard: shieldArtboard,
          size: Vector2.all(300),
          anchor: Anchor.center,
        );
        _shieldRives.add(newComponent);
        add(newComponent);
        _shieldRives.last.decorator.addLast(
          PaintDecorator.tint(type.intenseColor),
        );
      });
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final riveShieldDisplacement = Vector2(
      -9,
      22,
    );
    for (final rive in _shieldRives) {
      rive.position = (size / 2) + riveShieldDisplacement;
    }
  }

  @override
  void updateTree(double dt) {
    update(dt);
    for (var c in children) {
      if (c is RiveComponent) {
        c.update(dt * (1.0 / _shieldCount));
      }
    }
  }
}
