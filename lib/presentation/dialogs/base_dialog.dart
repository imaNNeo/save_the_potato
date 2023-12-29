import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/dialogs/settings_dialog.dart';

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

  static void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: 'Settings',
        content: const SettingsDialogContent(),
      ),
    );
  }
}
