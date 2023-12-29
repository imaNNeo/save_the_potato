import 'package:flutter/material.dart';

class GameRoundButton extends StatelessWidget {
  const GameRoundButton({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
  });

  final String title;
  final Widget? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
