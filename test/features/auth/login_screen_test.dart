import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/auth/application/usecases/login.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_branding.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_exception.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/domain/entities/setup_token_validation.dart';
import 'package:nytroz_pos/features/auth/domain/entities/tenant_payment_status.dart';
import 'package:nytroz_pos/features/auth/domain/entities/tenant_payment_summary.dart';
import 'package:nytroz_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/login_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders tenant sign-in form', (tester) async {
      await _pumpLoginScreen(tester);

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Sign in to continue to Nytroz POS'), findsOneWidget);
      expect(find.text('Tenant Code'), findsNothing);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows validation errors when required fields are empty', (
      tester,
    ) async {
      await _pumpLoginScreen(tester);

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows auth error when login fails', (tester) async {
      await _pumpLoginScreen(
        tester,
        login: _FailingLogin(
          const AuthException(
            errorCode: 'INVALID_CREDENTIALS',
            message: 'Invalid login or password.',
          ),
        ),
      );

      await tester.enterText(
          find.byType(TextFormField).at(0), 'cashier@test.local');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'wrong-password');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid login or password. (INVALID_CREDENTIALS)'),
        findsOneWidget,
      );
    });

    testWidgets('attaches auth header via authHeaderSyncProvider after login', (
      tester,
    ) async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      String? headerWhenSessionChanged;

      await _pumpLoginScreen(
        tester,
        dio: dio,
        sessionListener: (ref) {
          ref.listen<AuthSession?>(authSessionProvider, (_, next) {
            if (next != null) {
              headerWhenSessionChanged =
                  dio.options.headers['Authorization']?.toString();
            }
          });
        },
      );

      await tester.enterText(
          find.byType(TextFormField).at(0), 'cashier@test.local');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(headerWhenSessionChanged, 'Bearer access-token');
    });
  });
}

Future<void> _pumpLoginScreen(
  WidgetTester tester, {
  Login? login,
  Dio? dio,
  void Function(WidgetRef ref)? sessionListener,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(
          dio ?? Dio(BaseOptions(baseUrl: 'https://test.local')),
        ),
        authSessionStorageProvider.overrideWithValue(
          _TestAuthSessionStorage(),
        ),
        loginProvider.overrideWithValue(
          login ?? Login(_SuccessfulAuthRepository()),
        ),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, child) {
            ref.watch(authHeaderSyncProvider);
            sessionListener?.call(ref);
            return const LoginScreen();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _SuccessfulAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return const AuthSession(
      accessToken: 'access-token',
      userId: 'user-1',
      userDisplayName: 'Cashier User',
    );
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

class _FailingLogin extends Login {
  _FailingLogin(this.error) : super(_SuccessfulAuthRepository());

  final AuthException error;

  @override
  Future<AuthSession> call({
    required String email,
    required String password,
  }) async {
    throw error;
  }
}

class _TestAuthSessionStorage extends AuthSessionStorage {
  _TestAuthSessionStorage() : super(const FlutterSecureStorage());

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}
