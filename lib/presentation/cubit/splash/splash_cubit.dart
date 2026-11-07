import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/loading_progress.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._configsRepository) : super(const SplashState());

  final ConfigsRepository _configsRepository;

  /// Everything the splash waits for, shown as its loading meter
  final _progress = LoadingProgress({
    _appStep: 1,
    _audioStep: AudioHelper.loadSteps,
    _imagesStep: PotatoGame.preloadCount,
  });
  static const _appStep = 'app';
  static const _audioStep = 'audio';
  static const _imagesStep = 'images';

  void _report(String step, int done) {
    _progress.report(step, done);
    if (isClosed) return;
    emit(state.copyWith(loadingProgress: _progress.value));
  }

  /// Popups wait this long after the splash opens, so its animation can play
  static const _popupDelay = Duration(milliseconds: 1000);

  Future<(int min, int latest, String storeUrl)>
  _getMinAndLatestVersion() async {
    final gameConfigs = await _configsRepository.getGameConfig();
    if (AppUtils.isIOS) {
      return (
        gameConfigs.minVersionIos,
        gameConfigs.latestVersionIos,
        gameConfigs.iosStoreUrl,
      );
    }

    return (
      gameConfigs.minVersionAndroid,
      gameConfigs.latestVersionAndroid,
      gameConfigs.androidStoreUrl,
    );
  }

  Future<bool> _initialChecks() async {
    final opened = DateTime.now();
    final images = PotatoGame.preloadAssets(
      onProgress: (done) => _report(_imagesStep, done),
    );
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersionCode = int.parse(packageInfo.buildNumber);
    emit(
      state.copyWith(
        showingVersion: AppUtils.formatVersionName(packageInfo.version),
      ),
    );

    final (minVersion, latestVersion, storeLink) =
        await _getMinAndLatestVersion();

    final forceUpdate = currentVersionCode < minVersion;
    _report(_appStep, 1);

    if (!forceUpdate) {
      emit(state.copyWith(versionIsAllowed: true));
      emit(state.copyWith(versionIsAllowed: false));
    }

    try {
      await getIt.get<AudioHelper>().initialize(
        onProgress: (done) => _report(_audioStep, done),
      );
    } catch (e) {
      AppUtils.recordError(e, StackTrace.current);
    }
    _progress.finish(_audioStep);
    try {
      await images;
    } catch (e) {
      AppUtils.recordError(e, StackTrace.current);
    }
    _report(_imagesStep, PotatoGame.preloadCount);

    /// Wait for splash animations before showing popups. Loading already
    /// took some of that time
    final waited = DateTime.now().difference(opened);
    if (waited < _popupDelay) {
      await Future.delayed(_popupDelay - waited);
    }

    if (forceUpdate) {
      emit(
        state.copyWith(
          showUpdatePopup: ValueWrapper(
            UpdateInfo(forced: true, storeLink: storeLink),
          ),
        ),
      );
      emit(state.copyWith(showUpdatePopup: const ValueWrapper(null)));
      return false;
    }

    final currentVersionMinor = (currentVersionCode ~/ 100) * 100;
    final latestVersionMinor = (latestVersion ~/ 100) * 100;
    final minorDiff = latestVersionMinor - currentVersionMinor;
    if (minorDiff >= 100) {
      emit(
        state.copyWith(
          showUpdatePopup: ValueWrapper(
            UpdateInfo(forced: false, storeLink: storeLink),
          ),
        ),
      );
      emit(state.copyWith(showUpdatePopup: const ValueWrapper(null)));
    }
    return true;
  }

  void pageOpen() async {
    final startTimestamp = DateTime.now().millisecondsSinceEpoch;
    final allowedToContinue = await _initialChecks();
    if (!allowedToContinue) {
      return;
    }
    final endTimestamp = DateTime.now().millisecondsSinceEpoch;
    final initialChecksDuration = endTimestamp - startTimestamp;
    final splashTotalDuration = (GameConstants.splashDuration * 1000).toInt();
    final splashDuration = splashTotalDuration - initialChecksDuration;
    await Future.delayed(Duration(milliseconds: splashDuration));
    emit(state.copyWith(openNextPage: true));
    emit(state.copyWith(openNextPage: false));
  }
}
