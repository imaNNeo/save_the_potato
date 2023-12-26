import 'package:flutter/material.dart';

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
              child: showGuide ? const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: bottomPadding,
                    left: edgePadding,
                  ),
                  child: SafeArea(
                    child: Icon(
                      Icons.undo_rounded,
                      size: 80,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ) : const SizedBox(),
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
              child: showGuide ? const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: bottomPadding,
                    right: edgePadding,
                  ),
                  child: SafeArea(
                    child: Icon(
                      Icons.redo_rounded,
                      size: 80,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ): const SizedBox(),
            ),
          ),
        ),
      ],
    );
  }
}