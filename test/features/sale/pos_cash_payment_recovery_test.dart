import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/data/datasources/pos_checkout_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_intent_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/screens/pos_cash_payment_screen.dart';

const _session = AuthSession(
    accessToken: 'test-token',
    userId: 'test-cashier',
    userDisplayName: 'Test Cashier',
    permissionCodes: [
      'pos.sales.checkout.execute',
      'pos.payments.cash.accept'
    ]);

class _Storage extends AuthSessionStorage {
  _Storage() : super(const AppSecureStorage(FlutterSecureStorage()));
  @override
  Future<AuthSession?> read() async => _session;
}

class _Session extends AuthSessionNotifier {
  _Session() : super(_Storage()) {
    state = _session;
  }
}

void main() {
  for (final status in ['unknown', 'succeeded', 'not_completed']) {
    testWidgets('unknown recovery never starts payment; status=$status',
        (tester) async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
        requests.add(request);
        handler
            .resolve(Response(requestOptions: request, statusCode: 200, data: {
          'data': {
            'status': status,
            if (status == 'succeeded')
              'payment': {
                'saleId': 'original-sale',
                'receiptNumber': 'original-receipt',
                'completedAt': '2026-09-11T06:00:00Z',
                'grandTotal': 100,
                'cashReceived': 120,
                'changeDue': 20,
                'items': [],
                'receiptDataJson': '{"contractVersion":2}',
              },
          },
        }));
      }));
      final container = ProviderContainer(overrides: [
        authSessionProvider.overrideWith((ref) => _Session()),
        posCheckoutRemoteDatasourceProvider
            .overrideWithValue(PosCheckoutRemoteDatasource(dio)),
      ]);
      addTearDown(container.dispose);
      final intent = container.read(posCashPaymentIntentProvider.notifier);
      final key = intent
          .beginSubmission(
              saleIdentity: 'original-cart',
              requestFingerprint: 'original-request')
          .key;
      intent.markUnknown();
      final originalCart = container.read(posNewSaleCartProvider);
      final router = GoRouter(initialLocation: '/cash', routes: [
        GoRoute(
            path: '/cash',
            builder: (context, state) =>
                const Scaffold(body: PosCashPaymentScreen())),
        GoRoute(
            path: '/pos/new-sale/payment/cash/success',
            builder: (context, state) =>
                const Scaffold(body: Text('Recovered receipt'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      expect(find.text('COMPLETE SALE'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('cash-check-payment-status')));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(requests.single.method, 'POST');
      expect(requests.single.path, endsWith('/payment-status'));
      expect((requests.single.data as Map)['idempotencyKey'], key);
      expect(container.read(posCashPaymentIntentProvider)!.key, key);
      if (status == 'succeeded') {
        expect(find.text('Recovered receipt'), findsOneWidget);
        expect(container.read(posCashPaymentSuccessProvider)!.saleId,
            'original-sale');
        expect(container.read(posCashPaymentSuccessProvider)!.changeDue, 20);
        expect(container.read(posNewSaleCartProvider).completedSaleId,
            'original-sale');
        expect(
            () => intent.beginSubmission(
                saleIdentity: 'original-cart',
                requestFingerprint: 'original-request'),
            throwsStateError);
      } else if (status == 'not_completed') {
        expect(container.read(posCashPaymentIntentProvider)!.phase,
            CashPaymentIntentPhase.knownRejected);
        expect(identical(container.read(posNewSaleCartProvider), originalCart),
            isTrue);
        await tester.tap(find.byKey(const ValueKey('cash-start-new-attempt')));
        await tester.pump();
        expect(container.read(posCashPaymentIntentProvider)!.key, isNot(key));
        expect(requests, hasLength(1));
      } else {
        expect(container.read(posCashPaymentIntentProvider)!.phase,
            CashPaymentIntentPhase.unknown);
        expect(identical(container.read(posNewSaleCartProvider), originalCart),
            isTrue);
        expect(find.byKey(const ValueKey('cash-check-payment-status')),
            findsOneWidget);
        expect(() => intent.startNew('original-cart'), throwsStateError);
      }
    });
  }

  testWidgets('known rejection exposes deliberate new attempt', (tester) async {
    final container = ProviderContainer(overrides: [
      authSessionProvider.overrideWith((ref) => _Session()),
    ]);
    addTearDown(container.dispose);
    final intent = container.read(posCashPaymentIntentProvider.notifier);
    final first = intent.beginSubmission(
        saleIdentity: 'cart', requestFingerprint: 'request');
    intent.markKnownRejected();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child:
            const MaterialApp(home: Scaffold(body: PosCashPaymentScreen()))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cash-start-new-attempt')));
    await tester.pump();
    expect(container.read(posCashPaymentIntentProvider)!.phase,
        CashPaymentIntentPhase.draft);
    expect(container.read(posCashPaymentIntentProvider)!.key, isNot(first.key));
  });
}
