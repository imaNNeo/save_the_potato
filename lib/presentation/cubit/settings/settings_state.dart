part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.audioEnabled = true,
    this.versionName = '',
  });

  final bool audioEnabled;
  final String versionName;

  SettingsState copyWith({
    bool? audioEnabled,
    String? versionName,
  }) {
    return SettingsState(
      audioEnabled: audioEnabled ?? this.audioEnabled,
      versionName: versionName ?? this.versionName,
    );
  }

  @override
  List<Object?> get props => [
        audioEnabled,
        versionName,
      ];
}
