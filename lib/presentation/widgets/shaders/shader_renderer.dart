import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// This widgets renders a [FragmentShader] in the box that is provided for it
///
/// [timeScale] is the speed at which the time is passed to the shader, we use
/// the normal ticker to update the time, then we multiply it by [timeScale]
///
/// [initialTimeOffset] is the initial time that is passed to the shader,
/// this is useful if you want to have some warmup time before the shader starts
class ShaderRendererWidget extends StatefulWidget {
  const ShaderRendererWidget({
    super.key,
    required this.shader,
    this.timeScale = 1.0,
    this.initialTimeOffset = 0.0,
  });

  final FragmentShader shader;

  final double timeScale;
  final double initialTimeOffset;

  @override
  State<ShaderRendererWidget> createState() => _ShaderRendererWidgetState();
}

class _ShaderRendererWidgetState extends State<ShaderRendererWidget>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  @override
  void initState() {
    _ticker = createTicker((elapsed) {
      setState(() {
        widget.shader.setFloat(
          0,
          widget.initialTimeOffset +
              ((elapsed.inMilliseconds / 1000) * widget.timeScale),
        );
      });
    });
    _ticker!.start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      widget.shader.setFloat(1, size.width);
      widget.shader.setFloat(2, size.height);
      return CustomPaint(
        painter: _ShaderPainter(widget.shader),
        size: size,
      );
    });
  }

  @override
  void dispose() {
    _ticker!.dispose();
    _ticker = null;
    super.dispose();
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.shader);

  final FragmentShader shader;
  final Paint shaderPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, size.height),
      shaderPaint..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
