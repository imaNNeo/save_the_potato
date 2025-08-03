import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashState());

  void pageOpen() async {
    await Future.delayed(
      Duration(milliseconds: (GameConstants.splashDuration * 1000).toInt()),
    );
    emit(state.copyWith(openNextPage: true));
    emit(state.copyWith(openNextPage: false));
  }
}
