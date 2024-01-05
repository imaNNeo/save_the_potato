part of 'configs_cubit.dart';

class ConfigsState extends Equatable {
  const ConfigsState({
    this.gameConfig = GameConfigEntity.initialOfflineConfigs,
  });

  final GameConfigEntity gameConfig;

  ConfigsState copyWith({
    GameConfigEntity? gameConfig,
  }) {
    return ConfigsState(
      gameConfig: gameConfig ?? this.gameConfig,
    );
  }

  @override
  List<Object> get props => [
        gameConfig,
      ];
}
