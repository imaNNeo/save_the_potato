import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/pages/leaderboard_page.dart';
import 'package:save_the_potato/presentation/dialogs/settings_dialog_content.dart';

class BaseDialog extends AlertDialog {
  BaseDialog({
    super.key,
    required BuildContext context,
    required String title,
    required Widget content,
  }) : super(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(28.0),
            ),
          ),
          title: Row(
            children: [
              Text(title),
              Expanded(child: Container()),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: content,
        );

  static void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        context: context,
        title: 'Settings',
        content: const SettingsDialogContent(),
      ),
    );
  }
}
