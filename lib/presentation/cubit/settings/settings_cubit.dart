import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/repository/settings_repository.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._repository,
    this._audioHelper,
  ) : super(const SettingsState()) {
    initialize();
  }

  final SettingsRepository _repository;
  final AudioHelper _audioHelper;

  void initialize() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    emit(state.copyWith(
      versionName: AppUtils.formatVersionName(
        packageInfo.version,
      ),
    ));
    emit(state.copyWith(audioEnabled: await _repository.audioEnabled()));
    _audioHelper.setAudioEnabled(state.audioEnabled);
  }

  void setAudioEnabled(bool enabled) async {
    await _repository.setAudioEnabled(enabled);
    emit(state.copyWith(audioEnabled: enabled));
  }

  @override
  void onChange(Change<SettingsState> change) {
    super.onChange(change);
    final audioEnableChanged =
        change.currentState.audioEnabled != change.nextState.audioEnabled;
    if (audioEnableChanged) {
      _audioHelper.setAudioEnabled(change.nextState.audioEnabled);
    }
  }
}
