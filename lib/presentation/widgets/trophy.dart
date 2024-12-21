import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

class Trophy extends StatelessWidget {
  const Trophy({
    super.key,
    required this.score,
    this.size = 38,
  });

  final int? score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SvgPicture.asset(
            'assets/images/trophy/trophy.svg',
            width: size,
            colorFilter: const ColorFilter.mode(
              GameColors.leaderboardGoldenColor,
              BlendMode.srcATop,
            ),
          ),
        ],
      ),
    );
  }
}
