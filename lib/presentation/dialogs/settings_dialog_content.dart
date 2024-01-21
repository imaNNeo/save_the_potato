import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/service_locator.dart';

class SettingsDialogContent extends StatefulWidget {
  const SettingsDialogContent({super.key}) : super();

  @override
  State<SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<SettingsDialogContent> {
  final analyticsHelper = getIt.get<AnalyticsHelper>();

  @override
  void initState() {
    analyticsHelper.logSettingsPopupOpen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Audio',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              trailing: Switch(
                value: state.audioEnabled,
                onChanged: (bool? newValue) {
                  analyticsHelper.logSettingsAudioChanged(newValue!);
                  BlocProvider.of<SettingsCubit>(context)
                      .setAudioEnabled(newValue!);
                },
              ),
            ),
            Text(
              state.versionName,
              style: const TextStyle(
                fontFamily: 'Roboto',
              ),
            ),
          ],
        );
      },
    );
  }
}
