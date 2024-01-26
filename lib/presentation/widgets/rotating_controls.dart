import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RotationControls extends StatelessWidget {
  const RotationControls({
    super.key,
    required this.showGuide,
    required this.onLeftDown,
    required this.onLeftUp,
    required this.onRightDown,
    required this.onRightUp,
  });

  final bool showGuide;
  final VoidCallback onLeftDown;
  final VoidCallback onLeftUp;
  final VoidCallback onRightDown;
  final VoidCallback onRightUp;

  @override
  Widget build(BuildContext context) {
    const bottomPadding = 40.0;
    const edgePadding = 44.0;
    const iconSize = 88.0;
    const startOpacity = 0.3;
    const endOpacity = 1.0;
    const tapAndHoldText = 'TAP & HOLD';
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => onLeftDown(),
            onTapUp: (_) => onLeftUp(),
            onTapCancel: () => onLeftUp(),
            child: Container(
              height: double.infinity,
              color: Colors.transparent,
              child: showGuide
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: bottomPadding,
                          left: edgePadding,
                        ),
                        child: SafeArea(
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.undo_rounded,
                                size: iconSize,
                                color: Colors.white70,
                              ),
                              Text(tapAndHoldText),
                            ],
                          )
                              .animate(
                                autoPlay: true,
                                onPlay: (controller) => controller.repeat(
                                  reverse: true,
                                ),
                              )
                              .fade(
                                begin: startOpacity,
                                end: endOpacity,
                                delay: const Duration(milliseconds: 1400),
                                curve: Curves.easeOutExpo,
                                duration: const Duration(
                                  milliseconds: 700,
                                ),
                              ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => onRightDown(),
            onTapUp: (_) => onRightUp(),
            onTapCancel: () => onRightUp(),
            child: Container(
              height: double.infinity,
              color: Colors.transparent,
              child: showGuide
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: bottomPadding,
                          right: edgePadding,
                        ),
                        child: SafeArea(
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.redo_rounded,
                                size: iconSize,
                                color: Colors.white70,
                              ),
                              Text(tapAndHoldText),
                            ],
                          )
                              .animate(
                                autoPlay: true,
                                delay: const Duration(milliseconds: 2100),
                                onPlay: (controller) => controller.repeat(
                                  reverse: true,
                                ),
                              )
                              .fade(
                                begin: startOpacity,
                                end: endOpacity,
                                delay: const Duration(milliseconds: 1400),
                                curve: Curves.easeOutExpo,
                                duration: const Duration(
                                  milliseconds: 700,
                                ),
                              ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ],
    );
  }
}
