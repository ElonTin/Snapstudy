import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_tokens.dart';
import 'package:snapstudy/features/auth/domain/entities/user.dart';

void main() {
  group('User', () {
    test('initials from display name', () {
      const user = User(
        id: '1',
        email: 'a@b.com',
        displayName: 'Nguyen Van A',
      );
      expect(user.initials, 'NA');
    });

    test('initials from email when no display name', () {
      const user = User(id: '1', email: 'student@school.edu');
      expect(user.initials, 'S');
    });
  });

  group('AuthTokens', () {
    test('isExpired returns true when past expiresAt', () {
      final tokens = AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(tokens.isExpired, true);
    });

    test('isExpired returns false when no expiresAt', () {
      const tokens = AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
      );
      expect(tokens.isExpired, false);
    });
  });
}
