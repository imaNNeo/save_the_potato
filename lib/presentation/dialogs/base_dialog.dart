import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/presentation/cubit/splash/splash_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/account_already_exists.dart';
import 'package:save_the_potato/presentation/dialogs/captcha_dialog_content.dart';
import 'package:save_the_potato/presentation/dialogs/nickname_dialog_content.dart';
import 'package:save_the_potato/presentation/dialogs/settings_dialog_content.dart';

import 'auth_dialog_content.dart';
import 'share_score_dialog_content.dart';
import 'update_dialog_content.dart';

class BaseDialog extends AlertDialog {
  BaseDialog({
    super.key,
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
                Builder(
                  builder: (context) {
                    return IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    );
                  }
                ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 300,
            ),
            child: content,
          ),
        );

  static Future<T?> _showSimpleDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: 'Barrier',
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return builder(context);
      },
      transitionBuilder: (_, anim, __, child) {
        Tween<double> scaleTween = Tween(begin: 0.0, end: 1.0);
        return ScaleTransition(
          scale: scaleTween.animate(anim),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }

  static void showSettingsDialog(BuildContext context) {
    _showSimpleDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: 'Settings',
        content: const SettingsDialogContent(),
      ),
    );
  }

  static void showNicknameDialog(BuildContext context) {
    _showSimpleDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: 'Nickname:',
        content: const NicknameDialogContent(),
      ),
    );
  }

  static void showAuthDialog(BuildContext context) {
    _showSimpleDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: 'Sign in',
        content: const AuthDialogContent(),
      ),
    );
  }

  static void showAccountAlreadyExistsDialog(
    BuildContext context,
    AccountAlreadyExistsError error,
  ) {
    _showSimpleDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: 'Account Exists',
        content: AccountAlreadyExistsDialogContent(
          error: error,
        ),
      ),
    );
  }

  static void showHighScoreShareDialog(
    BuildContext context,
    UserEntity userEntity,
    OnlineScoreEntity scoreEntity,
  ) {
    _showSimpleDialog(
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: 'Share Score',
        content: HighScoreShareDialogContent(
          userEntity: userEntity,
          scoreEntity: scoreEntity,
        ),
      ),
    );
  }

  static Future<T?> showUpdateDialog<T>(
    BuildContext context,
    UpdateInfo info,
  ) {
    final title = info.forced ? 'Update Required' : 'Update Available';
    return _showSimpleDialog(
      barrierDismissible: !info.forced,
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: title,
        content: UpdateDialogContent(info: info),
        showCloseButton: !info.forced,
      ),
    );
  }

  static Future<bool> showCaptchaDialog<T>(
    BuildContext context,
  ) async {
    final result = await _showSimpleDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => BaseDialog(
        title: 'Are you a Robot?',
        content: const CaptchaDialogContent(),
        showCloseButton: false,
      ),
    );
    return result == true;
  }
}
