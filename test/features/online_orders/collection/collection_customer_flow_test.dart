import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/collection_handover_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/collection_complete_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/collection_qr_rejected_screen.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order_collection.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_order_collection_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/collection_qr_scan_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/collection_payment_success_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/collection_verification_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/pos_online_orders_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/widgets/oo01_online_orders_widgets.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../helpers/test_auth_session_storage.dart';

PosCollectionValidationResult _validResult({
  bool canTakePayment = false,
  bool canCollect = true,
}) =>
    PosCollectionValidationResult(
      orderId: 'order-1',
      orderNumber: 'ORD-100',
      customerName: 'Alex Customer',
      customerPhone: '07000000000',
      outletId: 'outlet-1',
      outletName: 'Main',
      fulfillmentStatus: 'READY',
      pickupStatus: 'READY',
      paymentStatus: canTakePayment ? 'UNPAID' : 'PAID',
      currency: 'GBP',
      total: 25,
      paidAmount: canTakePayment ? 0 : 25,
      balanceDue: canTakePayment ? 25 : 0,
      canCollect: canCollect,
      canTakePayment: canTakePayment,
      expectedVersion: 3,
      pickupNumber: 'P-12',
      items: const [
        PosCollectionItem(productName: 'Widget', quantityPacked: 2),
      ],
    );

class _FakeCollectionRepo implements PosOnlineOrdersRepository {
  int validateCalls = 0;
  int completeCalls = 0;
  Completer<PosCollectionValidationResult>? delayedValidate;
  PosCollectionValidationResult? nextValidation;
  Object? validateError;
  PosCollectionCompleteResult? nextComplete;

  @override
  Future<PosOnlineOrderPage> list(
    PosOnlineOrdersQuery query, {
    CancelToken? cancelToken,
  }) async {
    return PosOnlineOrderPage.fromJson({
      'items': const [],
      'totalPages': 1,
      'totalCount': 0,
    });
  }

  @override
  Future<PosCollectionValidationResult> validateCollectionQr({
    required String outletId,
    required String token,
    CancelToken? cancelToken,
  }) async {
    validateCalls++;
    if (validateError != null) {
      final error = validateError!;
      validateError = null;
      throw error;
    }
    if (delayedValidate != null) {
      return delayedValidate!.future;
    }
    return nextValidation ?? _validResult();
  }

  @override
  Future<PosCollectionCompleteResult> completeCollection({
    required String outletId,
    required String orderId,
    required int expectedVersion,
    CancelToken? cancelToken,
  }) async {
    completeCalls++;
    return nextComplete ??
        PosCollectionCompleteResult(
          orderId: orderId,
          orderNumber: 'ORD-100',
          pickupStatus: 'COLLECTED',
          fulfillmentStatus: 'FULFILLED',
          salesOrderStatus: 'COMPLETED',
          salesFulfillmentStatus: 'COLLECTED',
          collectedAt: DateTime.utc(2026, 9, 12, 10),
          fulfillmentVersion: expectedVersion + 1,
          alreadyCollected: false,
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container({
  required PosOnlineOrdersRepository repo,
  List<String> permissions = const [],
}) {
  return ProviderContainer(overrides: [
    posOnlineOrdersRepositoryProvider.overrideWithValue(repo),
    posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
    authSessionProvider.overrideWith(
      (ref) => PresetAuthSessionNotifier(
        AuthSession(
          accessToken: 'token',
          userId: 'u1',
          userDisplayName: 'Cashier',
          permissionCodes: permissions,
        ),
      ),
    ),
  ]);
}

List<String> get _scanPerms => [
      PosPermissionCodes.accessOnlineOrders,
      PosPermissionCodes.viewOnlineOrders,
      PosPermissionCodes.scanOnlineOrderCollectionQr,
      PosPermissionCodes.validateOnlineOrderCollectionQr,
      PosPermissionCodes.manualOnlineOrderCollectionLookup,
      PosPermissionCodes.handoverOnlineOrderCollection,
      PosPermissionCodes.collectOnlineOrder,
    ];

void main() {
  for (final size in [
    const Size(1280, 800),
    const Size(1180, 820),
    const Size(1100, 700)
  ]) {
    for (final primary in [
      TenantAdminColors.primary,
      const Color(0xFFFF1493)
    ]) {
      testWidgets('collection theme and layout matrix $size $primary',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _FakeCollectionRepo();
        final container = _container(repo: repo, permissions: _scanPerms);
        addTearDown(container.dispose);
        container
            .read(posOnlineOrderCollectionProvider.notifier)
            .seedValidationForTest(
                _validResult(canTakePayment: true, canCollect: false));
        for (final screen in <Widget>[
          const CollectionQrScanScreen(),
          const CollectionVerificationScreen(),
          const CollectionQrRejectedScreen(),
          const CollectionHandoverScreen(),
          const CollectionCompleteScreen(),
        ]) {
          container
              .read(posOnlineOrderCollectionProvider.notifier)
              .seedValidationForTest(
                  _validResult(canTakePayment: true, canCollect: false));
          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: primary)
                      .copyWith(primary: primary)),
              home: Scaffold(body: screen),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: screen.runtimeType.toString());
          for (final button in tester.widgetList<PosPrimaryActionButton>(
              find.byType(PosPrimaryActionButton))) {
            expect(button.backgroundColor, isNull);
            expect(button.gradient, isNull);
          }
          if (screen is CollectionHandoverScreen) {
            expect(
                tester
                    .widget<PosPrimaryActionButton>(
                        find.byKey(const Key('collection-mark-collected')))
                    .onPressed,
                isNull);
          }
          if (screen is CollectionCompleteScreen) {
            expect(
                tester
                    .widget<Icon>(find
                        .byKey(const Key('collection-complete-success-icon')))
                    .color,
                TenantAdminColors.success);
          }
          if (screen is CollectionQrRejectedScreen) {
            expect(
                tester.widget<Icon>(find.byIcon(Icons.qr_code_scanner)).color,
                TenantAdminColors.danger);
          }
        }
        expect(repo.completeCalls, 0);
      });
    }
  }
  test('collection permission helpers require chained codes', () {
    final queue = {
      PosPermissionCodes.accessOnlineOrders,
      PosPermissionCodes.viewOnlineOrders,
    };
    expect(PosPermissionAccess.canScanCollectionQr(queue), isFalse);
    expect(
      PosPermissionAccess.canScanCollectionQr({
        ...queue,
        PosPermissionCodes.scanOnlineOrderCollectionQr,
      }),
      isTrue,
    );
    expect(
      PosPermissionAccess.canValidateCollectionQr({
        ...queue,
        PosPermissionCodes.scanOnlineOrderCollectionQr,
      }),
      isFalse,
    );
    expect(
      PosPermissionAccess.canValidateCollectionQr({
        ...queue,
        PosPermissionCodes.scanOnlineOrderCollectionQr,
        PosPermissionCodes.validateOnlineOrderCollectionQr,
      }),
      isTrue,
    );
    expect(
      PosPermissionAccess.canHandoverCollection({
        ...queue,
        PosPermissionCodes.handoverOnlineOrderCollection,
      }),
      isFalse,
    );
    expect(
      PosPermissionAccess.canHandoverCollection({
        ...queue,
        PosPermissionCodes.handoverOnlineOrderCollection,
        PosPermissionCodes.collectOnlineOrder,
      }),
      isTrue,
    );
    expect(
      PosPermissionAccess.canManualCollectionLookup({
        ...queue,
        PosPermissionCodes.manualOnlineOrderCollectionLookup,
      }),
      isTrue,
    );
  });

  testWidgets('OO-01 collection QR action renders when permission present',
      (tester) async {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PosOnlineOrdersScreen())),
    ));
    await tester.pump();
    expect(find.byKey(const Key('oo01-collection-qr')), findsOneWidget);
    expect(find.byTooltip('Scan customer collection QR'), findsOneWidget);
    expect(find.byTooltip('Scan order'), findsOneWidget);
  });

  testWidgets('OO-01 collection QR action hidden without permission',
      (tester) async {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: [
      PosPermissionCodes.accessOnlineOrders,
      PosPermissionCodes.viewOnlineOrders,
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PosOnlineOrdersScreen())),
    ));
    await tester.pump();
    expect(find.byKey(const Key('oo01-collection-qr')), findsNothing);
    expect(find.byTooltip('Scan order'), findsOneWidget);
  });

  testWidgets('search scan still available beside collection action',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Oo01Header(
          searchController: TextEditingController(),
          onSearch: (_) {},
          onScan: () {},
          onCollectionQr: () {},
        ),
      ),
    ));
    expect(find.byTooltip('Scan order'), findsOneWidget);
    expect(find.byTooltip('Scan customer collection QR'), findsOneWidget);
  });

  test('validate success moves to VALID_READY and payment does not complete',
      () async {
    final repo = _FakeCollectionRepo()..nextValidation = _validResult();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);

    await container
        .read(posOnlineOrderCollectionProvider.notifier)
        .validateToken('tok-1');
    expect(
      container.read(posOnlineOrderCollectionProvider).phase,
      PosCollectionPhase.validReady,
    );
    expect(repo.completeCalls, 0);

    container
        .read(posOnlineOrderCollectionProvider.notifier)
        .markPaymentSettled(saleId: 'sale-9');
    expect(
      container.read(posOnlineOrderCollectionProvider).phase,
      PosCollectionPhase.paymentSuccess,
    );
    expect(repo.completeCalls, 0);
    expect(
      container.read(posOnlineOrderCollectionProvider).lastPaymentSaleId,
      'sale-9',
    );
  });

  test('validate payment-required phase when canTakePayment', () async {
    final repo = _FakeCollectionRepo()
      ..nextValidation = _validResult(canTakePayment: true, canCollect: false);
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    await container
        .read(posOnlineOrderCollectionProvider.notifier)
        .validateToken('tok-pay');
    expect(
      container.read(posOnlineOrderCollectionProvider).phase,
      PosCollectionPhase.paymentRequired,
    );
  });

  test('collection balance passes whole units to shared checkout', () {
    expect(
      _validResult(canTakePayment: true).balanceDueCheckoutAmount,
      25,
    );
  });

  test('settled payment removes the cached payment-required state', () {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    container
        .read(posOnlineOrderCollectionProvider.notifier)
        .seedValidationForTest(
          _validResult(canTakePayment: true, canCollect: false),
          phase: PosCollectionPhase.paymentRequired,
        );

    container
        .read(posOnlineOrderCollectionProvider.notifier)
        .markPaymentSettled(saleId: 'sale-10');

    final state = container.read(posOnlineOrderCollectionProvider);
    expect(state.phase, PosCollectionPhase.paymentSuccess);
    expect(state.validation?.paymentStatus, 'PAID');
    expect(state.validation?.balanceDue, 0);
    expect(state.validation?.canTakePayment, isFalse);
    expect(state.validation?.canCollect, isTrue);
  });

  test('duplicate validate suppressed while validating', () async {
    final delayed = Completer<PosCollectionValidationResult>();
    final repo = _FakeCollectionRepo()..delayedValidate = delayed;
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);

    final first = container
        .read(posOnlineOrderCollectionProvider.notifier)
        .validateToken('a');
    final second = container
        .read(posOnlineOrderCollectionProvider.notifier)
        .validateToken('b');
    await Future<void>.delayed(Duration.zero);
    expect(repo.validateCalls, 1);
    delayed.complete(_validResult());
    await Future.wait([first, second]);
    expect(repo.validateCalls, 1);
  });

  test('handover calls complete once', () async {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    await container
        .read(posOnlineOrderCollectionProvider.notifier)
        .validateToken('tok');
    container.read(posOnlineOrderCollectionProvider.notifier).prepareHandover();

    final first = container
        .read(posOnlineOrderCollectionProvider.notifier)
        .completeHandover();
    final second = container
        .read(posOnlineOrderCollectionProvider.notifier)
        .completeHandover();
    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(repo.completeCalls, 1);
    expect(
      container.read(posOnlineOrderCollectionProvider).phase,
      PosCollectionPhase.collectionComplete,
    );
  });

  testWidgets('scan screen has title and manual entry', (tester) async {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: CollectionQrScanScreen())),
    ));
    await tester.pump();
    expect(find.text('Scan Customer Collection QR'), findsOneWidget);
    expect(find.text('Enter Order Number Manually'), findsOneWidget);
    expect(find.byKey(const Key('collection-manual-entry')), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
  });

  testWidgets('manual collection sheet owns its focused controller',
      (tester) async {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: CollectionQrScanScreen())),
    ));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const Key('collection-manual-entry')));
    await tester.tap(find.byKey(const Key('collection-manual-entry')));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('collection-manual-code-field'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'opaque-code');
    Navigator.of(tester.element(field)).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('verification shows payment CTA when canTakePayment',
      (tester) async {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    container
        .read(posOnlineOrderCollectionProvider.notifier)
        .seedValidationForTest(
          _validResult(canTakePayment: true, canCollect: false),
          phase: PosCollectionPhase.paymentRequired,
        );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: CollectionVerificationScreen()),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const Key('collection-take-payment')), findsOneWidget);
    expect(find.byKey(const Key('collection-confirm-handover')), findsNothing);
  });

  testWidgets('verification shows handover CTA when paid and canCollect',
      (tester) async {
    final repo = _FakeCollectionRepo();
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    container
        .read(posOnlineOrderCollectionProvider.notifier)
        .seedValidationForTest(
          _validResult(),
          phase: PosCollectionPhase.validReady,
        );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: CollectionVerificationScreen()),
      ),
    ));
    await tester.pump();
    expect(
        find.byKey(const Key('collection-confirm-handover')), findsOneWidget);
    expect(find.byKey(const Key('collection-take-payment')), findsNothing);
  });

  for (final size in [
    const Size(1280, 800),
    const Size(1180, 820),
    const Size(1100, 700)
  ]) {
    for (final pink in [TenantAdminColors.primary, const Color(0xFFFF1493)]) {
      testWidgets(
          'payment success shows cash details and only continues to handover $size $pink',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _FakeCollectionRepo();
        final container = _container(repo: repo, permissions: _scanPerms);
        addTearDown(container.dispose);
        container
            .read(posOnlineOrderCollectionProvider.notifier)
            .seedValidationForTest(
              _validResult(),
              phase: PosCollectionPhase.paymentSuccess,
              lastPaymentSaleId: 'sale-9',
            );
        container
            .read(posCashPaymentSuccessProvider.notifier)
            .recordCheckoutPayment(_paymentPayload());

        final router = GoRouter(
          initialLocation: '/success',
          routes: [
            GoRoute(
              path: '/success',
              builder: (_, __) => const CollectionPaymentSuccessScreen(),
            ),
            GoRoute(
              path: '/pos/online-orders/collection/handover',
              builder: (_, __) => const Text('HANDOVER TARGET'),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: pink).copyWith(
                primary: pink,
              ),
            ),
            routerConfig: router,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Payment successful'), findsOneWidget);
        expect(find.text('ORD-100'), findsOneWidget);
        expect(find.text('GBP 25.00'), findsOneWidget);
        expect(find.text('GBP 30.00'), findsOneWidget);
        expect(find.text('GBP 5.00'), findsOneWidget);
        expect(find.text('Cash'), findsOneWidget);
        final successIcon = tester.widget<Icon>(
          find.byKey(const Key('collection-payment-success-icon')),
        );
        expect(successIcon.color, TenantAdminColors.success);
        final decoration = tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .map((widget) => widget.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((value) => value.color == pink);
        expect(decoration.color, pink);
        expect(repo.completeCalls, 0);

        await tester.tap(find.byKey(const Key('collection-continue-handover')));
        await tester.pumpAndSettle();
        expect(find.text('HANDOVER TARGET'), findsOneWidget);
        expect(repo.completeCalls, 0);
        expect(
          container.read(posOnlineOrderCollectionProvider).phase,
          PosCollectionPhase.handoverReady,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('invalid QR maps to rejected phase with safe message', () async {
    final repo = _FakeCollectionRepo()
      ..validateError = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: {'errorCode': 'online_orders.collection.qr_invalid'},
        ),
        type: DioExceptionType.badResponse,
      );
    final container = _container(repo: repo, permissions: _scanPerms);
    addTearDown(container.dispose);
    await container
        .read(posOnlineOrderCollectionProvider.notifier)
        .validateToken('bad');
    final state = container.read(posOnlineOrderCollectionProvider);
    expect(state.phase, PosCollectionPhase.invalidQr);
    expect(state.failureReason, PosCollectionFailureReason.qrInvalid);
    expect(state.errorMessage, contains('not valid'));
  });
}

PosCheckoutStartPaymentPayload _paymentPayload() =>
    PosCheckoutStartPaymentPayload(
      checkoutSessionId: 'checkout-1',
      saleId: 'sale-9',
      saleNumber: 'ORD-100',
      paymentMethod: 'CASH',
      grandTotal: 25,
      currency: 'GBP',
      saleStatus: 'COMPLETED',
      nextAction: 'HANDOVER',
      receiptNumber: 'R-1',
      barcodeValue: 'R-1',
      completedAt: DateTime.utc(2026, 9, 13),
      subtotal: 25,
      discount: 0,
      tax: 0,
      cashReceived: 30,
      changeDue: 5,
      items: const [],
    );
