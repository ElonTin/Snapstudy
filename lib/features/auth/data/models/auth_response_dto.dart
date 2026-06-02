import 'package:snapstudy/features/auth/data/models/user_dto.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_session.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_tokens.dart';

class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.expiresIn,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final userJson = data['user'] as Map<String, dynamic>? ??
        data['profile'] as Map<String, dynamic>? ??
        {};

    return AuthResponseDto(
      accessToken: data['accessToken'] as String? ??
          data['access_token'] as String? ??
          data['token'] as String? ??
          '',
      refreshToken: data['refreshToken'] as String? ??
          data['refresh_token'] as String? ??
          '',
      expiresIn: data['expiresIn'] as int? ?? data['expires_in'] as int?,
      user: UserDto.fromJson(userJson),
    );
  }

  final String accessToken;
  final String refreshToken;
  final UserDto user;
  final int? expiresIn;

  AuthSession toSession() {
    final expiresAt = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn!))
        : null;

    return AuthSession(
      user: user.toEntity(),
      tokens: AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      ),
    );
  }
}
