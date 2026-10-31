import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Left/right "hold" areas that rotate the shields.
///
/// Uses raw pointer events instead of tap gestures: a tap recognizer cancels
/// as soon as the finger drifts past the touch slop (~18px), which stopped
/// the rotation while the player was still holding. Each side also tracks
/// every finger on it, so it only releases when the last one lifts.
class RotationControls extends StatefulWidget {
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
  State<RotationControls> createState() => _RotationControlsState();
}

class _RotationControlsState extends State<RotationControls> {
  final _leftPointers = <int>{};
  final _rightPointers = <int>{};

  void _onPointerDown(PointerDownEvent event, {required bool isLeft}) {
    final pointers = isLeft ? _leftPointers : _rightPointers;
    if (pointers.isEmpty) {
      isLeft ? widget.onLeftDown() : widget.onRightDown();
    }
    pointers.add(event.pointer);
  }

  void _onPointerEnd(PointerEvent event, {required bool isLeft}) {
    final pointers = isLeft ? _leftPointers : _rightPointers;
    if (pointers.remove(event.pointer) && pointers.isEmpty) {
      isLeft ? widget.onLeftUp() : widget.onRightUp();
    }
  }

  @override
  void dispose() {
    if (_leftPointers.isNotEmpty) {
      widget.onLeftUp();
    }
    if (_rightPointers.isNotEmpty) {
      widget.onRightUp();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bottomPadding = 80.0;
    const edgePadding = 44.0;

    return Row(
      children: [
        Expanded(
          child: _holdArea(
            isLeft: true,
            child: widget.showGuide
                ? const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: bottomPadding,
                        left: edgePadding,
                      ),
                      child: SafeArea(child: _GuideWidget(isLeft: true)),
                    ),
                  )
                : const SizedBox(),
          ),
        ),
        Expanded(
          child: _holdArea(
            isLeft: false,
            child: widget.showGuide
                ? const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: bottomPadding,
                        right: edgePadding,
                      ),
                      child: SafeArea(child: _GuideWidget(isLeft: false)),
                    ),
                  )
                : const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _holdArea({required bool isLeft, required Widget child}) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _onPointerDown(event, isLeft: isLeft),
      onPointerUp: (event) => _onPointerEnd(event, isLeft: isLeft),
      onPointerCancel: (event) => _onPointerEnd(event, isLeft: isLeft),
      child: SizedBox(height: double.infinity, child: child),
    );
  }
}

class _GuideWidget extends StatelessWidget {
  const _GuideWidget({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    const tapAndHoldText = 'HOLD';
    const iconSize = 88.0;
    const startOpacity = 0.3;
    const endOpacity = 1.0;
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLeft ? Icons.undo_rounded : Icons.redo_rounded,
              size: iconSize,
              color: Colors.white70,
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
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scaleXY(
          begin: 1.0,
          end: 1.25,
          curve: Curves.fastOutSlowIn,
          delay: const Duration(milliseconds: 1400),
          duration: const Duration(milliseconds: 700),
        )
        .rotate(
          begin: 0.0,
          end: isLeft ? -0.013 : 0.013,
          curve: Curves.easeOut,
          delay: const Duration(milliseconds: 1400),
          duration: const Duration(milliseconds: 700),
        )
        .fade(
          begin: startOpacity,
          end: endOpacity,
          delay: const Duration(milliseconds: 1400),
          curve: Curves.easeOutExpo,
          duration: const Duration(milliseconds: 700),
        );
  }
}
