import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:ice_fire_game/my_game.dart';

void main() {
  final myGame = FlameGame(world: MyWorld());
  runApp(GameWidget(game: myGame));
}
