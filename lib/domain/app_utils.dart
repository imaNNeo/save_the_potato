import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

class AppUtils {
  static String getHighScoreRepresentation(int highScoreMilliseconds) {
    final minutes = highScoreMilliseconds ~/ 60000;
    final seconds = (highScoreMilliseconds % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static void showWarningToast(BuildContext context, String text) {
    toastification.show(
      context: context,
      title: text,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
    );
  }
  static void showSuccessToast(BuildContext context, String text) {
    toastification.show(
      context: context,
      title: text,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
    );
  }
}
