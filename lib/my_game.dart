import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import 'element.dart';
import 'player.dart';

class MyGame extends FlameGame<MyWorld>
    with PanDetector, HasCollisionDetection {
  MyGame()
      : super(
          world: MyWorld(),
          camera: CameraComponent.withFixedResolution(
            width: 800,
            height: 800,
          ),
        );

  @override
  void onPanStart(DragStartInfo info) => world.player.onPanStart(info);

  @override
  void onPanDown(DragDownInfo info) => world.player.onPanDown(info);

  @override
  void onPanUpdate(DragUpdateInfo info) => world.player.onPanUpdate(info);
}

class MyWorld extends World with HasGameRef<MyGame> {
  late Player player;

  @override
  Future<void> onLoad() async {
    await add(player = Player());
    add(TimerComponent(
      period: 1.5,
      repeat: true,
      onTick: _spawnSpawner,
    ));
  }

  double _getSpawnRandomDistance() {
    final distanceMin = player.size.x * 3;
    final distanceMax = game.size.x / 2;
    final distanceDiff = distanceMax - distanceMin;
    return distanceMin + Random().nextDouble() * distanceDiff;
  }

  void _spawnSpawner() {
    final distance = _getSpawnRandomDistance();
    final angle = Random().nextDouble() * pi * 2;
    final position = Vector2(cos(angle), sin(angle)) * distance;

    final spawner = ElementSpawner(
      position: position,
      type: TemperatureType.values[Random().nextInt(2)],
      spawnInterval: 0.0,
      spawnCount: 1,
    );
    add(spawner);
  }
}

enum TemperatureType {
  hot,
  cold;

  TemperatureType get opposite => switch (this) {
        TemperatureType.hot => TemperatureType.cold,
        TemperatureType.cold => TemperatureType.hot,
      };

  Color get color => switch (this) {
        TemperatureType.hot => Colors.red,
        TemperatureType.cold => Colors.blue,
      };
}
