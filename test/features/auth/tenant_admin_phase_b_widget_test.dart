import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_branding.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_exception.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/domain/entities/setup_token_validation.dart';
import 'package:nytroz_pos/features/auth/domain/entities/tenant_payment_status.dart';
import 'package:nytroz_pos/features/auth/domain/entities/tenant_payment_summary.dart';
import 'package:nytroz_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/payment_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/screens/set_password_screen.dart';
import 'package:nytroz_pos/features/auth/presentation/screens/setup_link_validation_screen.dart';
import 'package:nytroz_pos/features/auth/presentation/screens/setup_success_screen.dart';

class FakeAuthRepository implements AuthRepository {
  Future<SetupTokenValidation>? validateFuture;
  SetupTokenValidation? defaultValidation;
  Future<void>? setPasswordFuture;
  int setPasswordCallCount = 0;
  String? lastSetupToken;
  String? lastPassword;
  String? lastConfirmPassword;

  @override
  Future<SetupTokenValidation> validateSetupToken(String setupToken) {
    if (validateFuture != null) return validateFuture!;
    return Future.value(defaultValidation ??
        SetupTokenValidation(
          setupToken: setupToken,
          valid: true,
          expired: false,
          email: 'admin@example.test',
        ));
  }

  @override
  Future<void> setPassword({
    required String setupToken,
    required String password,
    required String confirmPassword,
  }) async {
    setPasswordCallCount++;
    lastSetupToken = setupToken;
    lastPassword = password;
    lastConfirmPassword = confirmPassword;
    if (setPasswordFuture != null) {
      await setPasswordFuture;
    }
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
  Future<AuthSession> login({required String login, required String password}) =>
      throw UnimplementedError();
}

Widget createTestHarness({
  required GoRouter router,
  required FakeAuthRepository repository,
  required WidgetTester tester,
}) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  const fakeToken = 'fake-test-token-123';

  group('SetupLinkValidationScreen Widget Tests', () {
    testWidgets('Loading State shows circular progress indicator', (tester) async {
      final completer = Completer<SetupTokenValidation>();
      final repo = FakeAuthRepository()..validateFuture = completer.future;

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken',
            builder: (context, state) => SetupLinkValidationScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Validating setup link'), findsOneWidget);

      completer.complete(const SetupTokenValidation(
        setupToken: fakeToken,
        valid: true,
        expired: false,
        email: 'admin@example.test',
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('Valid Token navigates to set password screen', (tester) async {
      final repo = FakeAuthRepository()
        ..defaultValidation = const SetupTokenValidation(
          setupToken: fakeToken,
          valid: true,
          expired: false,
          email: 'admin@example.test',
        );

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken',
            builder: (context, state) => SetupLinkValidationScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
          GoRoute(
            path: '/tenant-admin/setup/:setupToken/password',
            builder: (context, state) => SetPasswordScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      expect(find.byType(SetPasswordScreen), findsOneWidget);
      expect(find.text('Set your password'), findsOneWidget);
    });

    testWidgets('Invalid Token shows safe error state and back to login button', (tester) async {
      final repo = FakeAuthRepository()
        ..defaultValidation = const SetupTokenValidation(
          setupToken: fakeToken,
          valid: false,
          expired: false,
          message: 'This setup link is invalid.',
        );

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken',
            builder: (context, state) => SetupLinkValidationScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
          GoRoute(
            path: '/tenant-login',
            builder: (context, state) => const Scaffold(body: Text('Login Screen Destination')),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('This setup link is invalid.'), findsOneWidget);
      expect(find.text('Back to login'), findsOneWidget);

      await tester.tap(find.text('Back to login'));
      await tester.pumpAndSettle();
      expect(find.text('Login Screen Destination'), findsOneWidget);
    });

    testWidgets('Expired Token shows expired message', (tester) async {
      final repo = FakeAuthRepository()
        ..defaultValidation = const SetupTokenValidation(
          setupToken: fakeToken,
          valid: false,
          expired: true,
          message: 'This setup link has expired.',
        );

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken',
            builder: (context, state) => SetupLinkValidationScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('This setup link has expired.'), findsOneWidget);
      expect(find.text('Back to login'), findsOneWidget);
    });

    testWidgets('Used Token displays already-used denial message', (tester) async {
      final repo = FakeAuthRepository()
        ..defaultValidation = const SetupTokenValidation(
          setupToken: fakeToken,
          valid: false,
          expired: false,
          code: 'INVITE_USED',
          message: 'This invitation link has already been used.',
        );

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken',
            builder: (context, state) => SetupLinkValidationScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('This invitation link has already been used.'), findsOneWidget);
      expect(find.text('Back to login'), findsOneWidget);
    });
  });

  group('SetPasswordScreen Widget Tests', () {
    testWidgets('Basic Render displays new password, confirm password, and CTA button', (tester) async {
      final repo = FakeAuthRepository();

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken/password',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken/password',
            builder: (context, state) => SetPasswordScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Set your password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm Password'), findsOneWidget);
      expect(find.text('Set Password & Activate Account'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Password Policy Validation rejects invalid passwords', (tester) async {
      final repo = FakeAuthRepository();

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken/password',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken/password',
            builder: (context, state) => SetPasswordScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final submitBtn = find.text('Set Password & Activate Account');

      // 1. Empty password
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Password is required'), findsOneWidget);
      expect(repo.setPasswordCallCount, 0);

      // 2. Too short (< 8 chars)
      await tester.enterText(fields.at(1), 'Short1');
      await tester.enterText(fields.at(2), 'Short1');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(repo.setPasswordCallCount, 0);

      // 3. Missing uppercase
      await tester.enterText(fields.at(1), 'nouppercase123');
      await tester.enterText(fields.at(2), 'nouppercase123');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Use uppercase, lowercase, and numeric characters'), findsOneWidget);
      expect(repo.setPasswordCallCount, 0);

      // 4. Missing lowercase
      await tester.enterText(fields.at(1), 'NOLOWERCASE123');
      await tester.enterText(fields.at(2), 'NOLOWERCASE123');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Use uppercase, lowercase, and numeric characters'), findsOneWidget);
      expect(repo.setPasswordCallCount, 0);

      // 5. Missing numeric digit
      await tester.enterText(fields.at(1), 'NoDigitsHere');
      await tester.enterText(fields.at(2), 'NoDigitsHere');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Use uppercase, lowercase, and numeric characters'), findsOneWidget);
      expect(repo.setPasswordCallCount, 0);
    });

    testWidgets('Password Confirmation Test rejects mismatching confirmation', (tester) async {
      final repo = FakeAuthRepository();

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken/password',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken/password',
            builder: (context, state) => SetPasswordScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final submitBtn = find.text('Set Password & Activate Account');

      await tester.enterText(fields.at(1), 'ValidPassword123');
      await tester.enterText(fields.at(2), 'MismatchedPassword123');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords must match'), findsOneWidget);
      expect(repo.setPasswordCallCount, 0);
    });

    testWidgets('Successful Password Submission navigates to SetupSuccessScreen', (tester) async {
      final repo = FakeAuthRepository();

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken/password',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken/password',
            builder: (context, state) => SetPasswordScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
          GoRoute(
            path: '/tenant-admin/setup/success',
            builder: (context, state) => const SetupSuccessScreen(),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final submitBtn = find.text('Set Password & Activate Account');

      await tester.enterText(fields.at(1), 'ValidPassword123');
      await tester.enterText(fields.at(2), 'ValidPassword123');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(repo.setPasswordCallCount, 1);
      expect(repo.lastSetupToken, fakeToken);
      expect(find.byType(SetupSuccessScreen), findsOneWidget);
      expect(find.text('Account Activated Successfully'), findsOneWidget);
    });

    testWidgets('Failed Password Submission displays error banner without crash or navigation', (tester) async {
      final completer = Completer<void>();
      final repo = FakeAuthRepository()..setPasswordFuture = completer.future;

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken/password',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/:setupToken/password',
            builder: (context, state) => SetPasswordScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
          GoRoute(
            path: '/tenant-admin/setup/success',
            builder: (context, state) => const SetupSuccessScreen(),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final submitBtn = find.text('Set Password & Activate Account');

      await tester.enterText(fields.at(1), 'ValidPassword123');
      await tester.enterText(fields.at(2), 'ValidPassword123');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      completer.completeError(
        AuthException(
          errorCode: 'INVITE_EXPIRED',
          message: 'This invitation link has expired.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This invitation link has expired. Ask your administrator to resend it.'), findsOneWidget);
      expect(find.byType(SetupSuccessScreen), findsNothing);
    });
  });

  group('SetupSuccessScreen Widget Tests', () {
    testWidgets('SetupSuccessScreen displays confirmation and redirects to /tenant-login', (tester) async {
      final repo = FakeAuthRepository();

      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/success',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/success',
            builder: (context, state) => const SetupSuccessScreen(),
          ),
          GoRoute(
            path: '/tenant-login',
            builder: (context, state) => const Scaffold(body: Text('Tenant Login Destination')),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Account Activated Successfully'), findsOneWidget);
      expect(find.text('Your ONEVERZ Tenant Administrator account is ready.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Continue to login'), findsOneWidget);

      await tester.tap(find.text('Continue to login'));
      await tester.pumpAndSettle();

      expect(find.text('Tenant Login Destination'), findsOneWidget);
    });
  });

  group('Phase B End-to-End Routing Sequence Test', () {
    testWidgets('Full sequence from setup link to login', (tester) async {
      final repo = FakeAuthRepository()
        ..defaultValidation = const SetupTokenValidation(
          setupToken: fakeToken,
          valid: true,
          expired: false,
          email: 'admin@example.test',
        );

      // Note: In canonical auth_router.dart, static segment /setup/success precedes /setup/:setupToken
      final router = GoRouter(
        initialLocation: '/tenant-admin/setup/$fakeToken',
        routes: [
          GoRoute(
            path: '/tenant-admin/setup/success',
            builder: (context, state) => const SetupSuccessScreen(),
          ),
          GoRoute(
            path: '/tenant-admin/setup/:setupToken',
            builder: (context, state) => SetupLinkValidationScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
          GoRoute(
            path: '/tenant-admin/setup/:setupToken/password',
            builder: (context, state) => SetPasswordScreen(
              setupToken: state.pathParameters['setupToken'] ?? '',
            ),
          ),
          GoRoute(
            path: '/tenant-login',
            builder: (context, state) => const Scaffold(body: Text('Welcome to Nytroz Login')),
          ),
        ],
      );

      await tester.pumpWidget(createTestHarness(router: router, repository: repo, tester: tester));
      await tester.pumpAndSettle();

      // Step 1: Validated setup link -> on password screen
      expect(find.byType(SetPasswordScreen), findsOneWidget);

      // Step 2: Fill passwords and submit
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'ValidPassword123');
      await tester.enterText(fields.at(2), 'ValidPassword123');

      final submitBtn = find.text('Set Password & Activate Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Step 3: Success screen reached
      expect(find.byType(SetupSuccessScreen), findsOneWidget);
      expect(find.text('Account Activated Successfully'), findsOneWidget);

      // Step 4: Continue to login
      final continueBtn = find.text('Continue to login');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Nytroz Login'), findsOneWidget);
    });
  });
}
