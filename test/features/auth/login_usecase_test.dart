import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/application/usecases/login.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_branding.dart';
import 'package:nytroz_pos/features/auth/domain/entities/setup_token_validation.dart';
import 'package:nytroz_pos/features/auth/domain/entities/tenant_payment_status.dart';
import 'package:nytroz_pos/features/auth/domain/entities/tenant_payment_summary.dart';
import 'package:nytroz_pos/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('Login use case', () {
    test('delegates tenant login to repository', () async {
      const expectedSession = AuthSession(
        accessToken: 'access-token',
        userId: 'user-1',
        userDisplayName: 'Cashier User',
        permissionCodes: ['pos.home.view'],
      );
      final repository = _FakeAuthRepository(session: expectedSession);
      final login = Login(repository);

      final result = await login.call(
        tenantCode: 'TENANT001',
        login: 'cashier@test.local',
        password: 'password123',
      );

      expect(result, expectedSession);
      expect(repository.lastTenantCode, 'TENANT001');
      expect(repository.lastLogin, 'cashier@test.local');
      expect(repository.lastPassword, 'password123');
    });

    test('returns unauthenticated session when repository does', () async {
      const session = AuthSession(
        accessToken: '',
        userId: 'user-1',
        userDisplayName: 'Cashier User',
      );
      final login = Login(_FakeAuthRepository(session: session));

      final result = await login.call(
        tenantCode: 'TENANT001',
        login: 'cashier@test.local',
        password: 'wrong-password',
      );

      expect(result.isAuthenticated, isFalse);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.session});

  final AuthSession session;
  String? lastTenantCode;
  String? lastLogin;
  String? lastPassword;

  @override
  Future<AuthSession> login({
    required String tenantCode,
    required String login,
    required String password,
  }) async {
    lastTenantCode = tenantCode;
    lastLogin = login;
    lastPassword = password;
    return session;
  }

  @override
  Future<AuthBranding> getAuthBranding() => throw UnimplementedError();

  @override
  Future<TenantPaymentSummary> getPaymentSummary(String paymentToken) =>
      throw UnimplementedError();

  @override
  Future<TenantPaymentStatus> startPayment(String paymentToken) =>
      throw UnimplementedError();

  @override
  Future<TenantPaymentStatus> verifyPaymentStatus(String paymentToken) =>
      throw UnimplementedError();

  @override
  Future<SetupTokenValidation> validateSetupToken(String setupToken) =>
      throw UnimplementedError();

  @override
  Future<void> setPassword({
    required String setupToken,
    required String password,
    required String confirmPassword,
  }) =>
      throw UnimplementedError();
}
