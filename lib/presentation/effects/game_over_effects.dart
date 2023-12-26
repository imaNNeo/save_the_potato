import 'package:flame/effects.dart';
import 'package:flutter/cupertino.dart';

import 'camera_zoom_effect.dart';

class GameOverCameraZoomEffect extends CameraZoomEffect {
  GameOverCameraZoomEffect()
      : super(
          controller: EffectController(
            duration: 1.0,
            curve: Curves.easeOut,
          ),
          zoomTo: 2,
        );
}
