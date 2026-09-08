import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/auth/domain/entities/setup_token_validation.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_exception.dart';
import 'package:nytroz_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/payment_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/screens/set_password_screen.dart';
import 'package:nytroz_pos/features/auth/presentation/screens/setup_link_validation_screen.dart';
import 'package:nytroz_pos/features/auth/presentation/screens/setup_success_screen.dart';

class InvitationRepository implements AuthRepository {
  Future<SetupTokenValidation>? pending;
  bool valid = true;
  bool expired = false;
  int saves = 0;
  int validations = 0;
  String? savedToken;
  Future<void>? mutation;
  @override
  Future<SetupTokenValidation> validateSetupToken(String token) {
    validations++;
    return pending ??
        Future.value(SetupTokenValidation(
          setupToken: token,
          valid: valid,
          expired: expired,
          email: 'invited@example.test',
          message: valid ? null : 'Invitation unavailable',
        ));
  }

  @override
  Future<void> setPassword(
      {required String setupToken,
      required String password,
      required String confirmPassword}) async {
    saves++;
    savedToken = setupToken;
    await mutation;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> open(WidgetTester tester, InvitationRepository repository,
    {String token = 'invite', bool landing = false}) async {
  tester.view.physicalSize = const Size(900, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(initialLocation: '/start', routes: [
    GoRoute(
        path: '/start',
        builder: (_, __) => landing
            ? SetupLinkValidationScreen(setupToken: token)
            : SetPasswordScreen(setupToken: token)),
    GoRoute(
        path: '/tenant-admin/setup/:token/password',
        builder: (_, state) =>
            SetPasswordScreen(setupToken: state.pathParameters['token']!)),
    GoRoute(
        path: '/tenant-admin/setup/success',
        builder: (_, __) => const SetupSuccessScreen()),
    GoRoute(
        path: '/tenant-login',
        builder: (_, __) =>
            const Scaffold(body: Text('Email and password login'))),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router)));
  return router;
}

void main() {
  testWidgets('mutation disables fields and ignores repeated activation',
      (tester) async {
    final pending = Completer<void>();
    final repository = InvitationRepository()..mutation = pending.future;
    await open(tester, repository);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Password1');
    await tester.enterText(fields.at(2), 'Password1');
    final submit = find.text('Set Password & Activate Account');
    await tester.ensureVisible(submit);
    final submitPosition = tester.getCenter(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.tapAt(submitPosition);
    await tester.pump();
    expect(repository.saves, 1);
    expect(tester.widget<TextFormField>(fields.at(1)).enabled, isFalse);
    expect(find.text('Account Activated Successfully'), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Account Activated Successfully'), findsOneWidget);
  });

  for (final code in ['PASSWORD_INVALID', 'NETWORK_ERROR', 'SERVER_ERROR']) {
    testWidgets('$code mutation does not claim activation', (tester) async {
      final pending = Completer<void>();
      final repository = InvitationRepository()..mutation = pending.future;
      await open(tester, repository);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password1');
      final submit = find.text('Set Password & Activate Account');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      pending.completeError(
          AuthException(errorCode: code, message: 'Please retry setup'));
      await tester.pumpAndSettle();
      expect(find.text('Please retry setup'), findsOneWidget);
      expect(find.text('Account Activated Successfully'), findsNothing);
    });
  }

  testWidgets('used invitation shows backend denial without form',
      (tester) async {
    final repository = InvitationRepository()
      ..pending = Future.value(const SetupTokenValidation(
          setupToken: 'invite',
          valid: false,
          expired: false,
          code: 'INVITE_USED',
          message: 'This invitation link has already been used.'));
    await open(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('This invitation link has already been used.'),
        findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
      'direct password URL hides fields until token verification completes',
      (tester) async {
    final pending = Completer<SetupTokenValidation>();
    final repository = InvitationRepository()..pending = pending.future;
    await open(tester, repository);
    await tester.pump();
    expect(find.byType(TextFormField), findsNothing);
    expect(repository.saves, 0);
    pending.complete(const SetupTokenValidation(
        setupToken: 'invite', valid: true, expired: false));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  for (final state in ['invalid', 'expired', 'missing', 'error']) {
    testWidgets('$state token never exposes password form', (tester) async {
      final repository = InvitationRepository()
        ..valid = state != 'invalid'
        ..expired = state == 'expired';
      if (state == 'error') {
        repository.pending = Future<SetupTokenValidation>.delayed(
            Duration.zero, () => throw Exception('offline'));
      }
      await open(tester, repository, token: state == 'missing' ? '' : 'invite');
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(repository.saves, 0);
      if (state == 'missing') expect(repository.validations, 0);
    });
  }

  testWidgets(
      'verified invitation validates confirmation then activates and offers login',
      (tester) async {
    final repository = InvitationRepository();
    await open(tester, repository, landing: true);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Password123!');
    await tester.enterText(fields.at(2), 'Different123!');
    final submit = find.text('Set Password & Activate Account');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Passwords must match'), findsOneWidget);
    expect(repository.saves, 0);
    await tester.enterText(fields.at(2), 'Password123!');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.saves, 1);
    expect(repository.savedToken, 'invite');
    expect(find.text('Account Activated Successfully'), findsOneWidget);
    await tester.tap(find.text('Continue to login'));
    await tester.pumpAndSettle();
    expect(find.text('Email and password login'), findsOneWidget);
  });
}
