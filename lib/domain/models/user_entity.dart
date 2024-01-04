enum UserType {
  anonymous,
  signedIn,
}

sealed class UserEntity {
  abstract final String uid;
  abstract final String nickname;
  abstract final UserType type;

  Map<String, dynamic> toJson();

  static UserEntity fromJson(Map<String, dynamic> json) {
    final type = UserType.values.firstWhere(
      (element) => element.name == json['type'] as String,
    );
    return switch (type) {
      UserType.anonymous => AnonymousUserEntity(
          uid: json['uid'] as String,
          nickname: json['nickname'] as String,
        ),
      UserType.signedIn => SignedInUserEntity(
          uid: json['uid'] as String,
          nickname: json['nickname'] as String,
          email: json['email'] as String,
        ),
    };
  }
}

class AnonymousUserEntity extends UserEntity {
  AnonymousUserEntity({
    required this.uid,
    required this.nickname,
  });

  @override
  final String uid;

  @override
  final String nickname;

  @override
  final UserType type = UserType.anonymous;

  @override
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nickname': nickname,
        'type': type.name,
      };
}

class SignedInUserEntity extends UserEntity {
  SignedInUserEntity({
    required this.uid,
    required this.nickname,
    required this.email,
  });

  @override
  final String uid;

  @override
  final String nickname;

  @override
  final UserType type = UserType.signedIn;

  final String email;

  @override
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nickname': nickname,
        'email': email,
        'type': type.name,
      };
}
