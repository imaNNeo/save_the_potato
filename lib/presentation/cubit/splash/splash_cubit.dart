import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/service_locator.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashState());

  void pageOpen() async {
    final startTimestamp = DateTime.now().millisecondsSinceEpoch;
    try {
      await getIt.get<AudioHelper>().initialize();
    } catch (e) {
      debugPrint('Error initializing audio: $e');
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
