import 'package:flutter/material.dart';

class BaseDialog extends AlertDialog {
  BaseDialog({
    super.key,
    required String title,
    required Widget content,
  }) : super(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(28.0),
            ),
          ),
          title: Text(title),
          content: content,
        );
}
