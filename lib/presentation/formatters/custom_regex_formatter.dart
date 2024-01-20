import 'package:flutter/services.dart';

class CustomRegexFormatter extends TextInputFormatter {
  final String regex;

  CustomRegexFormatter(this.regex);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    bool isInserting = newText.length > oldText.length;
    bool isSingleSpace = newText.endsWith(' ') && !oldText.endsWith(' ') && isInserting;

    if (isSingleSpace && newText.trim().isNotEmpty) {
      return newValue;
    } else if (newText.isNotEmpty && !RegExp(regex).hasMatch(newText)) {
      return oldValue;
    } else if (newText.contains('  ')) {
      return oldValue;
    }
    return newValue;
  }
}