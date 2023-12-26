import 'dart:ui';

import 'package:flame/effects.dart';
import 'package:flame/components.dart';
import 'package:save_the_potato/presentation/my_game.dart';

class CameraZoomEffect extends Effect with HasGameRef<MyGame> {
  CameraZoomEffect({
    required EffectController controller,
    required this.zoomTo,
  }) : super(controller);

  final double zoomTo;
  late double zoomFrom;

  @override
  void onStart() {
    zoomFrom = game.camera.viewfinder.zoom;
    super.onStart();
  }

  @override
  void apply(double progress) {
    game.camera.viewfinder.zoom = lerpDouble(zoomFrom, zoomTo, progress)!;
  }
}
