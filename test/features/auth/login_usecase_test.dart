import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/application/usecases/login.dart';
import 'package:nytroz_pos/features/auth/data/models/login_request_dto.dart';
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
        email: 'cashier@test.local',
        password: 'password123',
      );

      expect(result, expectedSession);
      expect(repository.lastEmail, 'cashier@test.local');
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
        email: 'cashier@test.local',
        password: 'wrong-password',
      );

      expect(result.isAuthenticated, isFalse);
    });

    test('login request body contains email and password only', () {
      const request = LoginRequestDto(
        email: 'cashier001@gmail.com',
        password: '123456',
      );

      expect(request.toJson(), {
        'email': 'cashier001@gmail.com',
        'password': '123456',
      });
      expect(request.toJson().containsKey('tenantCode'), isFalse);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.session});

  final AuthSession session;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
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
