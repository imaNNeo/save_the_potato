import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/widgets/game_round_button.dart';

import 'trophy.dart';

class NewRankCelebrationOverlay extends StatefulWidget {
  final OnlineScoreEntity scoreEntity;

  const NewRankCelebrationOverlay({super.key, required this.scoreEntity});

  @override
  State<NewRankCelebrationOverlay> createState() =>
      _NewRankCelebrationOverlayState();
}

class _NewRankCelebrationOverlayState extends State<NewRankCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
    super.initState();
  }

  @override
  Widget build(Object context) {
    return LayoutBuilder(
      builder: (context, constrants) {
        final width = constrants.maxWidth;
        final height = constrants.maxHeight;
        final trophySize = min(width * 0.5, 200.0);
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12.0,
                sigmaY: 12.0,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(
                  0.8,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(width, height),
                  painter: _WinningLinesPainter(
                    startingPoint: _animationController.value * pi * 2,
                  ),
                );
              },
            ),
            Column(
              children: [
                Expanded(
                  flex: 5,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 48),
                        const Text(
                          'SAVE THE POTATO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              shadows: [
                                Shadow(
                                  color: GameColors.gameBlue,
                                  offset: Offset(0, 0),
                                  blurRadius: 8,
                                ),
                              ]),
                        ),
                        const Expanded(child: SizedBox()),
                        const Text(
                          'score:',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        Text(
                          AppUtils.getHighScoreRepresentation(
                              widget.scoreEntity.score),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 0),
                      ],
                    ),
                  ),
                ),
                Trophy(
                  score: widget.scoreEntity,
                  size: trophySize,
                ),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 200,
                          child: GameRoundButton(
                            title: 'SHARE SCORE',
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _WinningLinesPainter extends CustomPainter {
  final double startingPoint;
  final Color color1 = Colors.white10;
  final Color color2 = Colors.white24;

  _WinningLinesPainter({
    this.startingPoint = 0.0,
  });

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    int linesCount = 16;
    double step = (pi * 2) / linesCount;
    final center = (size / 2).toOffset();
    final longestSize = max(size.width, size.height);
    for (int i = 0; i < linesCount; i++) {
      double degree = startingPoint + (step * i);
      Path path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + longestSize * cos(degree),
          center.dy + longestSize * sin(degree),
        )
        ..lineTo(
          center.dx + longestSize * cos(degree + step),
          center.dy + longestSize * sin(degree + step),
        );
      canvas.drawPath(
        path,
        _paint
          ..color = i.isEven ? color1 : color2
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WinningLinesPainter oldDelegate) =>
      oldDelegate.startingPoint != startingPoint;
}
