import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shaders/shader_renderer.dart';

class ShieldShader extends StatefulWidget {
  const ShieldShader({
    super.key,
    required this.timeScale,
  });

  final double timeScale;

  @override
  State<ShieldShader> createState() => _ShieldShaderState();
}

class _ShieldShaderState extends State<ShieldShader> {
  ui.FragmentShader? _backgroundShader;

  @override
  void initState() {
    asyncInit();
    super.initState();
  }

  void asyncInit() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/shield.frag');
    setState(() {
      _backgroundShader = program.fragmentShader();
      _refreshShaderParams();
    });
  }

  @override
  void didUpdateWidget(covariant ShieldShader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshShaderParams();
  }

  void _refreshShaderParams() {
    const color = Colors.red;
    // _backgroundShader?.setFloat(3, color.red / 255);
    // _backgroundShader?.setFloat(4, color.green / 255);
    // _backgroundShader?.setFloat(5, color.blue / 255);
  }

  @override
  Widget build(BuildContext context) {
    if (_backgroundShader == null) {
      return const SizedBox();
    }
    return ShaderRendererWidget(
      shader: _backgroundShader!,
      initialTimeOffset: 1000.0,
      timeScale: widget.timeScale,
    );
  }
}
