import 'package:snapstudy/features/auth/domain/entities/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String?,
      photoUrl: json['photoUrl'] as String? ?? json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

  User toEntity() => User(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

  static UserDto fromEntity(User user) => UserDto(
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      );
}
