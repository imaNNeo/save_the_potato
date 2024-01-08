import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/game_config_entity.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';

part 'configs_state.dart';

class ConfigsCubit extends Cubit<ConfigsState> {
  ConfigsCubit(this._configsRepository) : super(const ConfigsState());

  final ConfigsRepository _configsRepository;
  late StreamSubscription _configsSubscription;

  void initialize() {
    _configsSubscription =
        _configsRepository.getGameConfigStream().listen((gameConfig) {
      emit(state.copyWith(gameConfig: gameConfig));
    });
  }

  @override
  Future<void> close() {
    _configsSubscription.cancel();
    return super.close();
  }
}
