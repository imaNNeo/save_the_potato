import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

class SplashPotato extends StatefulWidget {
  const SplashPotato({super.key, this.size = 300});
  final double size;

  @override
  State<SplashPotato> createState() => _SplashPotatoState();
}

class _SplashPotatoState extends State<SplashPotato> {
  /// Plays the 'Initialize' animation once
  final _painter = SingleAnimationPainter('Initialize');
  File? _file;
  Artboard? _artboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final file = await File.asset(
      'assets/rive/potato.riv',
      riveFactory: Factory.flutter,
    );
    if (!mounted) {
      file?.dispose();
      return;
    }
    setState(() {
      _file = file;
      _artboard = file?.defaultArtboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final artboard = _artboard;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: artboard == null
          ? null
          : Transform.scale(
              scale: 1.45,
              child: RiveArtboardWidget(artboard: artboard, painter: _painter),
            ),
    );
  }

  @override
  void dispose() {
    _painter.dispose();
    _artboard?.dispose();
    _file?.dispose();
    super.dispose();
  }
}
