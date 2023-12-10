import 'package:flutter/material.dart';

class ReplyButton extends StatelessWidget {
  const ReplyButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: SizedBox(
        width: 80,
        height: 80,
        child: ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          onPressed: onPressed,
          child: const Icon(Icons.replay),
        ),
      ),
    );
  }
}
