import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/presentation/cubit/splash/splash_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/account_already_exists.dart';
import 'package:save_the_potato/presentation/dialogs/nickname_dialog_content.dart';
import 'package:save_the_potato/presentation/dialogs/settings_dialog_content.dart';

import 'auth_dialog_content.dart';
import 'update_dialog_content.dart';

class BaseDialog extends AlertDialog {
  BaseDialog({
    super.key,
    required BuildContext context,
    required String title,
    required Widget content,
    bool showCloseButton = true,
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
              if (showCloseButton)
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

  static void showNicknameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        context: context,
        title: 'Nickname:',
        content: const NicknameDialogContent(),
      ),
    );
  }

  static void showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        context: context,
        title: 'Sign in',
        content: const AuthDialogContent(),
      ),
    );
  }

  static void showAccountAlreadyExistsDialog(
    BuildContext context,
    AccountAlreadyExistsError error,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        context: context,
        title: 'Account Exists',
        content: AccountAlreadyExistsDialogContent(
          error: error,
        ),
      ),
    );
  }

  static Future<T?> showUpdateDialog<T>(
    BuildContext context,
    UpdateInfo info,
  ) {
    final title = info.forced ? 'Update Required' : 'Update Available';
    return showDialog(
      barrierDismissible: !info.forced,
      context: context,
      builder: (BuildContext context) => BaseDialog(
        context: context,
        title: title,
        content: UpdateDialogContent(info: info),
        showCloseButton: !info.forced,
      ),
    );
  }
}
