import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_tokens.dart';
import 'package:snapstudy/features/auth/domain/entities/user.dart';

/// Active authenticated session (user + tokens).
class AuthSession extends Equatable {
  const AuthSession({
    required this.user,
    required this.tokens,
  });

  final User user;
  final AuthTokens tokens;

  @override
  List<Object?> get props => [user, tokens];
}
