import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/extensions/rect_extensions.dart';
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
    final textOffset = Vector2(0, -150);

    final textApproximateRect = Rect.fromCenter(
      center: textOffset.toOffset(),
      width: 340,
      height: 68,
    );
    const particlesCount = 10;

    final expandedRect = textApproximateRect.expandBy(80, 60);

    final particlesLifespan = totalDuration;
    final List<Sprite> sprites = [
      await Sprite.load('sparkle/sparkle1.png'),
      await Sprite.load('sparkle/sparkle2.png'),
    ];
    final randomSprites = List.generate(
      particlesCount,
      (i) => sprites.random(),
    );
    /// Motivation particles
    add(ParticleSystemComponent(
      priority: 0,
      particle: Particle.generate(
        count: particlesCount,
        lifespan: particlesLifespan,
        generator: (i) {
          final randomPoint = expandedRect.randomPointExcludeRect(
            textApproximateRect,
          );
          return AcceleratedParticle(
            position: randomPoint,
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final sprite = randomSprites[i];
                final scaleProgress = TweenSequence(
                  <TweenSequenceItem<double>>[
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 0.8),
                      weight: 1,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 0.8, end: 1.0),
                      weight: 3,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 1.0, end: 0.0),
                      weight: 1,
                    ),
                  ],
                ).transform(
                  Curves.fastOutSlowIn.transform(
                    particle.progress,
                  ),
                );
                final size =
                    Tween(begin: 0.0, end: 18.0).transform(scaleProgress);

                final opacityTween = TweenSequence(
                  <TweenSequenceItem<double>>[
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 1.0),
                      weight: 1,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 1.0, end: 0.0),
                      weight: 1,
                    ),
                  ],
                );
                canvas.rotate(particle.progress * pi * 2);
                sprite.render(
                  canvas,
                  size: Vector2.all(size),
                  anchor: Anchor.center,
                  overridePaint: Paint()
                    ..colorFilter = ColorFilter.mode(
                      color.withOpacity(
                        opacityTween.transform(particle.progress),
                      ),
                      BlendMode.srcIn,
                    ),
                );
              },
            ),
          );
        },
      ),
    ));

    add(_textComponent = TextComponent(
      priority: 2,
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
          textOffset,
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
    add(RemoveEffect(
      delay: max(totalDuration, particlesLifespan),
    ));
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
  goodJob('Good Job!', 'good_job.wav'),
  ohGreat('Oh Great!', 'oh_great.wav'),
  ohNice('Oh Nice!', 'oh_nice.wav'),
  perfect('Perfect!', 'perfect.wav');

  final String text;
  final String assetName;

  const MotivationWordType(this.text, this.assetName);
}
