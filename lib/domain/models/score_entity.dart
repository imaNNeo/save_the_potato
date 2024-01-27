import 'package:equatable/equatable.dart';

sealed class ScoreEntity with EquatableMixin {
  abstract final int score;

  static ScoreEntity fromJson(jsonDecode) => switch (jsonDecode['type']) {
        OfflineScoreEntity._type => OfflineScoreEntity.fromJson(jsonDecode),
        OnlineScoreEntity._type => OnlineScoreEntity.fromJson(jsonDecode),
        _ => throw Exception('Unknown type ${jsonDecode['type']}'),
      };

  Map<String, dynamic> toJson() => throw UnimplementedError();
}

class OfflineScoreEntity extends ScoreEntity {
  static const _type = 'offline';

  @override
  final int score;

  OfflineScoreEntity({
    required this.score,
  });

  OfflineScoreEntity copyWith({
    int? score,
  }) =>
      OfflineScoreEntity(
        score: score ?? this.score,
      );

  @override
  Map<String, dynamic> toJson() => {
        'score': score,
        'type': _type,
      };

  factory OfflineScoreEntity.fromJson(Map<String, dynamic> json) =>
      OfflineScoreEntity(
        score: json['score'],
      );

  @override
  List<Object?> get props => [score];
}

class OnlineScoreEntity extends ScoreEntity {
  static const _type = 'online';

  @override
  final int score;
  final String userId;
  final String nickname;
  final bool isMine;
  final int rank;

  /// id is the same as [userId] in the database
  String get id => userId;

  OnlineScoreEntity({
    required this.score,
    required this.userId,
    required this.nickname,
    required this.isMine,
    required this.rank,
  });

  OnlineScoreEntity copyWith({
    int? score,
    String? userId,
    String? nickname,
    bool? isMine,
    int? rank,
  }) =>
      OnlineScoreEntity(
        score: score ?? this.score,
        userId: userId ?? this.userId,
        nickname: nickname ?? this.nickname,
        isMine: isMine ?? this.isMine,
        rank: rank ?? this.rank,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': _type,
        'score': score,
        'user_id': userId,
        'nickname': nickname,
        'is_mine': isMine,
        'rank': rank,
      };

  factory OnlineScoreEntity.fromJson(Map<String, dynamic> json) =>
      OnlineScoreEntity(
        score: json['score'],
        userId: json['user_id'],
        nickname: json['nickname'],
        isMine: json['is_mine'],
        rank: json['rank'],
      );

  @override
  List<Object?> get props => [
        score,
        userId,
        nickname,
        isMine,
        rank,
      ];
}
