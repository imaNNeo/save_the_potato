class ScoreEntity {
  final int score;
  final String userId;
  final String nickname;
  final bool isMine;
  final int rank;

  ScoreEntity({
    required this.score,
    required this.userId,
    required this.nickname,
    required this.isMine,
    required this.rank,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'user_id': userId,
        'nickname': nickname,
        'is_mine': isMine,
        'rank': rank,
      };

  factory ScoreEntity.fromJson(Map<String, dynamic> json) => ScoreEntity(
        score: json['score'],
        userId: json['user_id'],
        nickname: json['nickname'],
        isMine: json['is_mine'],
        rank: json['rank'],
      );
}
