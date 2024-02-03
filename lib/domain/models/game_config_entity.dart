import 'package:equatable/equatable.dart';

class GameConfigEntity with EquatableMixin {
  /// This is the hard-coded instance for when user opens the app for the
  /// first time without internet.
  /// We will update it later when user connects to internet.
  static const initialOfflineConfigs = GameConfigEntity(
    nicknameMaxLength: 25,
    nicknameMinLength: 3,
    nicknameAllowedRegex: '[0-9a-zA-Z ]',
    minVersionAndroid: 0,
    minVersionIos: 0,
    latestVersionAndroid: 0,
    latestVersionIos: 0,
    androidStoreUrl:
        'https://play.google.com/store/apps/details?id=dev.app2pack.ttg',
    iosStoreUrl:
        'https://apps.apple.com/app/ttg-through-the-galaxy/id6444870791',
    shareTextWithRank:
        "🌟 I'm in the top 10! Just hit a new high score of {{score}} on Save The Potato and secured the #{{rank}} spot! 🏆 Can you climb higher? Grab the game at savethepotato.com and take on the challenge! 🥔🛡️ #SaveThePotato #HighScore",
    shareTextWithoutRank:
        "🏆 New High Score on Save The Potato! 🎉 Just hit a new high score of {{score}} on Save The Potato! 🥔🛡️ Can you climb higher? Grab the game at savethepotato.com and take on the challenge! #SaveThePotato #HighScore",
    shareTextWithRankThreshold: 10,
    showNewScoreCelebrationRankThreshold: 20,
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
  final String shareTextWithRank;
  final String shareTextWithoutRank;
  final int shareTextWithRankThreshold;
  final int showNewScoreCelebrationRankThreshold;

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
    required this.shareTextWithRank,
    required this.shareTextWithoutRank,
    required this.shareTextWithRankThreshold,
    required this.showNewScoreCelebrationRankThreshold,
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
        'shareTextWithRank': shareTextWithRank,
        'shareTextWithoutRank': shareTextWithoutRank,
        'shareTextWithRankThreshold': shareTextWithRankThreshold,
        'showNewScoreCelebrationRankThreshold':
            showNewScoreCelebrationRankThreshold,
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
        shareTextWithRank: json['shareTextWithRank'] as String,
        shareTextWithoutRank: json['shareTextWithoutRank'] as String,
        shareTextWithRankThreshold: json['shareTextWithRankThreshold'] as int,
        showNewScoreCelebrationRankThreshold:
            json['showNewScoreCelebrationRankThreshold'] as int,
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
        shareTextWithRank,
        shareTextWithoutRank,
        shareTextWithRankThreshold,
        showNewScoreCelebrationRankThreshold,
      ];
}
