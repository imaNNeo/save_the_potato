import 'package:flutter/foundation.dart';
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
    const bottomPadding = 80.0;
    const edgePadding = 44.0;

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
                  ? const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: bottomPadding,
                          left: edgePadding,
                        ),
                        child: SafeArea(
                          child: _GuideWidget(
                            isLeft: true,
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
                  ? const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: bottomPadding,
                          right: edgePadding,
                        ),
                        child: SafeArea(
                          child: _GuideWidget(
                            isLeft: false,
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

class _GuideWidget extends StatelessWidget {
  const _GuideWidget({
    required this.isLeft,
  });

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    const tapAndHoldText = 'HOLD';
    const iconSize = 88.0;
    const startOpacity = 0.3;
    const endOpacity = 1.0;

    bool isMobile = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    final leftIcon = switch (isMobile) {
      true => Icons.undo_rounded,
      false => Icons.arrow_back_rounded,
    };
    final rightIcon = switch(isMobile) {
      true => Icons.redo_rounded,
      false => Icons.arrow_forward_rounded,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLeft ? leftIcon : rightIcon,
          size: iconSize,
          color: Colors.white70,
        ),
        if (!isMobile)
          const SizedBox(
            height: 4.0,
          ),
        const Text(
          tapAndHoldText,
          style: TextStyle(
            fontSize: 22.0,
            height: -0.2,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    )
        .animate(
          autoPlay: true,
          delay: Duration(milliseconds: isLeft ? 0 : 2100),
          onPlay: (controller) => controller.repeat(
            reverse: true,
          ),
        )
        .scaleXY(
          begin: 1.0,
          end: 1.25,
          curve: Curves.fastOutSlowIn,
          delay: const Duration(milliseconds: 1400),
          duration: const Duration(
            milliseconds: 700,
          ),
        )
        .rotate(
          begin: 0.0,
          end: isLeft ? -0.013 : 0.013,
          curve: Curves.easeOut,
          delay: const Duration(milliseconds: 1400),
          duration: const Duration(
            milliseconds: 700,
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
        );
  }
}
