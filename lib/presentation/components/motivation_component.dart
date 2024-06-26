import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/service_locator.dart';

class MotivationComponent extends PositionComponent with HasPaint {
  final MotivationWordType motivationWordType;
  final Color color;
  late final AudioHelper _audioHelper;
  late final TextComponent _textComponent;
  final double inDuration;
  final double outDuration;


  double get totalDuration => inDuration + outDuration;

  MotivationComponent({
    super.position,
    this.color = GameColors.greenColor,
    required this.motivationWordType,
    required this.inDuration,
    required this.outDuration,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _audioHelper = getIt.get<AudioHelper>();
    _audioHelper.playMotivationWord(motivationWordType);
    add(_textComponent = TextComponent(
      text: motivationWordType.text,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          fontFamily: 'Cookies',
        ),
      ),
      children: [
        ScaleEffect.by(
          Vector2.all(2.5),
          EffectController(
            duration: inDuration,
            curve: Curves.fastOutSlowIn,
          ),
        ),
        MoveByEffect(
          Vector2(0, -150),
          EffectController(
            duration: inDuration,
            curve: Curves.fastOutSlowIn,
          ),
        ),
        OpacityEffect.to(
          0.7,
          target: this as OpacityProvider,
          EffectController(
            duration: inDuration,
            curve: Curves.fastOutSlowIn,
          ),
        ),
        OpacityEffect.fadeOut(
          target: this as OpacityProvider,
          EffectController(
            duration: outDuration,
            curve: Curves.fastOutSlowIn,
            startDelay: inDuration,
          ),
        )
      ],
    ));
    setOpacity(0);
    add(RemoveEffect(delay: totalDuration));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _textComponent.textRenderer =
        (_textComponent.textRenderer as TextPaint).copyWith(
      (style) => style.copyWith(
        color: color.withOpacity(opacity),
      ),
    );
  }
}

enum MotivationWordType {
  amazing('Amazing!', 'amazing.wav'),
  nice('Nice!', 'nice.wav'),
  goodJob('Good Job!', 'goodJob.wav'),
  wonderful('Wonderful!', 'wonderful.wav'),
  great('Great!', 'great.wav'),
  excellent('Excellent!', 'excellent.wav'),
  fantastic('Fantastic!', 'fantastic.wav'),
  awesome('Awesome!', 'awesome.wav'),
  perfect('Perfect!', 'perfect.wav');

  final String text;
  final String assetName;

  const MotivationWordType(this.text, this.assetName);
}
