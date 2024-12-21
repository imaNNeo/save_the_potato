part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.audioEnabled = true,
  });

  final bool audioEnabled;

  SettingsState copyWith({
    bool? audioEnabled,
  }) {
    return SettingsState(
      audioEnabled: audioEnabled ?? this.audioEnabled,
    );
  }

  @override
  List<Object?> get props => [
        audioEnabled,
      ];
}
