import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';

class SettingsDialogContent extends StatelessWidget {
  const SettingsDialogContent({super.key}) : super();

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
