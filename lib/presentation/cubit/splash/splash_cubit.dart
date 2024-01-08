import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._configsRepository) : super(const SplashState());

  final ConfigsRepository _configsRepository;

  Future<(int min, int latest, String storeUrl)>
      _getMinAndLatestVersion() async {
    final gameConfigs = await _configsRepository.getGameConfig();
    if (Platform.isIOS) {
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
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersionCode = int.parse(packageInfo.buildNumber);
    emit(state.copyWith(
      showingVersion: AppUtils.formatVersionName(
        packageInfo.version,
      ),
    ));

    final (minVersion, latestVersion, storeLink) =
        await _getMinAndLatestVersion();

    final forceUpdate = currentVersionCode < minVersion;

    if (!forceUpdate) {
      emit(state.copyWith(versionIsAllowed: true));
      emit(state.copyWith(versionIsAllowed: false));
    }

    /// Wait for splash animations before showing popups
    await Future.delayed(const Duration(milliseconds: 1000));

    if (forceUpdate) {
      emit(state.copyWith(
        showUpdatePopup: ValueWrapper(
          UpdateInfo(forced: true, storeLink: storeLink),
        ),
      ));
      emit(state.copyWith(
        showUpdatePopup: const ValueWrapper(null),
      ));
      return false;
    }

    final currentVersionMinor = (currentVersionCode ~/ 100) * 100;
    final latestVersionMinor = (latestVersion ~/ 100) * 100;
    final minorDiff = latestVersionMinor - currentVersionMinor;
    if (minorDiff >= 100) {
      emit(state.copyWith(
        showUpdatePopup: ValueWrapper(
          UpdateInfo(forced: false, storeLink: storeLink),
        ),
      ));
      emit(state.copyWith(
        showUpdatePopup: const ValueWrapper(null),
      ));
    }
    return true;
  }

  void pageOpen() async {
    final startTimestamp = DateTime.now().millisecondsSinceEpoch;
    final allowedToContiniue = await _initialChecks();
    if (!allowedToContiniue) {
      return;
    }
    final endTimestamp = DateTime.now().millisecondsSinceEpoch;
    final initialChecksDuration = endTimestamp - startTimestamp;
    final splashTotalDuration = (GameConstants.splashDuration * 1000).toInt();
    final splashDuration = splashTotalDuration - initialChecksDuration;
    await Future.delayed(
      Duration(milliseconds: splashDuration),
    );
    emit(state.copyWith(openNextPage: true));
    emit(state.copyWith(openNextPage: false));
  }
}
