import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class GameIconButton extends StatelessWidget {
  const GameIconButton({
    super.key,
    this.size = 48.0,
    required this.svgAssetName,
    this.onPressed,
  });

  final double size;
  final String svgAssetName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        icon: Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: SvgPicture.asset(
              'assets/images/icons/$svgAssetName',
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
