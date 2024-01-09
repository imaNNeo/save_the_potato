import 'dart:math';

import 'package:flutter/material.dart';

class CaptchaDialogContent extends StatefulWidget {
  const CaptchaDialogContent({super.key}) : super();

  @override
  State<CaptchaDialogContent> createState() => _CaptchaDialogContentState();
}

class _CaptchaDialogContentState extends State<CaptchaDialogContent> {
  late TextEditingController _controller;

  late int result;
  late String question;
  @override
  void initState() {
    _controller = TextEditingController();
    final int randomNumber1 = Random().nextInt(10);
    final int randomNumber2 = Random().nextInt(10);
    question = 'What is $randomNumber1 + $randomNumber2?';
    result = randomNumber1 + randomNumber2;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(question),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            hintStyle: TextStyle(color: Colors.grey[800]),
            fillColor: Colors.transparent,
            counterText: '',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          width: 118,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context)
                .pop(int.parse(_controller.text) == result),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
