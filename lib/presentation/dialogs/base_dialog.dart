import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/dialogs/settings_dialog_content.dart';

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
                Builder(builder: (context) {
                  return IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  );
                }),
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
}
