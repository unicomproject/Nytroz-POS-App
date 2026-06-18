import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/domain/utils/jwt_expiry.dart';

void main() {
  group('readJwtExpiry', () {
    test('reads exp claim from jwt payload', () {
      const token = 'header.eyJleHAiOjE3NTAxNjM4MjF9.signature';

      final expiry = readJwtExpiry(token);

      expect(expiry,
          DateTime.fromMillisecondsSinceEpoch(1750163821 * 1000, isUtc: true));
    });
  });

  group('AuthSession', () {
    test('treats expired sessions as unauthenticated', () {
      const session = AuthSession(
        accessToken: 'token',
        userId: 'user-1',
        userDisplayName: 'User',
        expiresAt: null,
      );

      final expiredSession = AuthSession(
        accessToken: session.accessToken,
        userId: session.userId,
        userDisplayName: session.userDisplayName,
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      expect(expiredSession.isExpired, isTrue);
      expect(expiredSession.isAuthenticated, isFalse);
    });
  });
}
