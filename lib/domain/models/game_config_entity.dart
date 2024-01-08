import 'package:equatable/equatable.dart';

class GameConfigEntity with EquatableMixin {
  /// This is the hard-coded instance for when user opens the app for the 
  /// first time without internet.
  /// We will update it later when user connects to internet.
  static const initialOfflineConfigs = GameConfigEntity(
    nicknameMaxLength: 25,
    nicknameMinLength: 3,
    nicknameAllowedRegex: '^[0-9a-zA-Z]+\$',
    minVersionAndroid: 0,
    minVersionIos: 0,
    latestVersionAndroid: 0,
    latestVersionIos: 0,
    androidStoreUrl: 'https://play.google.com/store/apps/details?id=dev.app2pack.ttg',
    iosStoreUrl: 'https://apps.apple.com/app/ttg-through-the-galaxy/id6444870791',
  );

  final int nicknameMaxLength;
  final int nicknameMinLength;
  final String nicknameAllowedRegex;
  final int minVersionAndroid;
  final int minVersionIos;
  final int latestVersionAndroid;
  final int latestVersionIos;
  final String androidStoreUrl;
  final String iosStoreUrl;

  const GameConfigEntity({
    required this.nicknameMaxLength,
    required this.nicknameMinLength,
    required this.nicknameAllowedRegex,
    required this.minVersionAndroid,
    required this.minVersionIos,
    required this.latestVersionAndroid,
    required this.latestVersionIos,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  Map<String, dynamic> toJson() => {
        'nicknameMaxLength': nicknameMaxLength,
        'nicknameMinLength': nicknameMinLength,
        'nicknameAllowedRegex': nicknameAllowedRegex,
        'minVersionAndroid': minVersionAndroid,
        'minVersionIos': minVersionIos,
        'latestVersionAndroid': latestVersionAndroid,
        'latestVersionIos': latestVersionIos,
        'androidStoreUrl': androidStoreUrl,
        'iosStoreUrl': iosStoreUrl,
      };

  factory GameConfigEntity.fromJson(Map<String, dynamic> json) =>
      GameConfigEntity(
        nicknameMaxLength: json['nicknameMaxLength'] as int,
        nicknameMinLength: json['nicknameMinLength'] as int,
        nicknameAllowedRegex: json['nicknameAllowedRegex'] as String,
        minVersionAndroid: json['minVersionAndroid'] as int,
        minVersionIos: json['minVersionIos'] as int,
        latestVersionAndroid: json['latestVersionAndroid'] as int,
        latestVersionIos: json['latestVersionIos'] as int,
        androidStoreUrl: json['androidStoreUrl'] as String,
        iosStoreUrl: json['iosStoreUrl'] as String,
      );

  @override
  List<Object?> get props => [
        nicknameMaxLength,
        nicknameMinLength,
        nicknameAllowedRegex,
        minVersionAndroid,
        minVersionIos,
        latestVersionAndroid,
        latestVersionIos,
        androidStoreUrl,
        iosStoreUrl,
      ];
}
