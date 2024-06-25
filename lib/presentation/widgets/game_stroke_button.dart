import 'package:flutter/material.dart';

class GameStrokeButton extends StatelessWidget {
  const GameStrokeButton({
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
    const height = 48.0;
    return SizedBox(
      height: height,
      child: MaterialButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Colors.white,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
