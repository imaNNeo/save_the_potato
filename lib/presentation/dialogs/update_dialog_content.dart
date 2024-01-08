import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/presentation/cubit/splash/splash_cubit.dart';

class UpdateDialogContent extends StatelessWidget {
  const UpdateDialogContent({
    super.key,
    required this.info,
  }) : super();

  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final updateDescription = info.forced
        ? 'Your version is outdated and you have to update the app'
        : 'There is a new version of the app. Do you want to update?';
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Roboto',
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(updateDescription),
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => AppUtils.tryToLaunchUrl(info.storeLink),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
