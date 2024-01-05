import 'package:equatable/equatable.dart';

class GameConfigEntity with EquatableMixin {
  static const initialOfflineConfigs = GameConfigEntity(
    nicknameMaxLength: 25,
    nicknameMinLength: 3,
    nicknameAllowedRegex: '^[0-9a-zA-Z]+\$',
  );

  final int nicknameMaxLength;
  final int nicknameMinLength;
  final String nicknameAllowedRegex;

  const GameConfigEntity({
    required this.nicknameMaxLength,
    required this.nicknameMinLength,
    required this.nicknameAllowedRegex,
  });

  Map<String, dynamic> toJson() => {
        'nicknameMaxLength': nicknameMaxLength,
        'nicknameMinLength': nicknameMinLength,
        'nicknameAllowedRegex': nicknameAllowedRegex,
      };

  factory GameConfigEntity.fromJson(Map<String, dynamic> json) =>
      GameConfigEntity(
        nicknameMaxLength: json['nicknameMaxLength'] as int,
        nicknameMinLength: json['nicknameMinLength'] as int,
        nicknameAllowedRegex: json['nicknameAllowedRegex'] as String,
      );

  @override
  List<Object?> get props => [
        nicknameMaxLength,
        nicknameMinLength,
        nicknameAllowedRegex,
      ];
}
