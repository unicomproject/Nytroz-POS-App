import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/pos/data/datasources/remote/pos_barcode_remote_datasource.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_barcode_lookup_result.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/new_sale/pos_barcode_scan_controller.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_barcode_scanner_listener.dart';

void main() {
  testWidgets(
      'HID completion flows through queue, lookup, mapping and cart action',
      (tester) async {
    final gateway = _FakeGateway();
    final added = <String>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        posBarcodeLookupGatewayProvider.overrideWithValue(gateway),
        posBarcodePrerequisitesProvider.overrideWithValue(
            () async => const PosBarcodePrerequisiteResult.success('device-1')),
        posBarcodeCartAddProvider.overrideWithValue((item, quantity) {
          added.add('${item.variantId}:$quantity');
          return PosCartMutationResult.added;
        }),
      ],
      child: const MaterialApp(home: _PipelineHarness()),
    ));

    for (final digit in '82111001003'.split('')) {
      await simulateKeyDownEvent(_digitKey(digit), character: digit);
    }
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(gateway.barcodes, ['82111001003']);
    expect(added, ['variant-1:2']);
  });

  test('successful scans are sequential, repeated scans are retained',
      () async {
    final gateway = _FakeGateway(delay: const Duration(milliseconds: 5));
    final quantities = <int>[];
    final container = _container(
      gateway: gateway,
      cartAdd: (_, quantity) {
        quantities.add(quantity);
        return quantities.length == 1
            ? PosCartMutationResult.added
            : PosCartMutationResult.quantityIncreased;
      },
    );
    addTearDown(container.dispose);

    final controller =
        container.read(posBarcodeScanControllerProvider.notifier);
    controller.enqueue('82111001003');
    controller.enqueue('82111001003');
    expect(
        container.read(posBarcodeScanControllerProvider).isProcessing, isTrue);
    await _waitForDrain(container);

    expect(gateway.barcodes, ['82111001003', '82111001003']);
    expect(gateway.maximumConcurrent, 1);
    expect(quantities, [2, 2]);
    expect(container.read(posBarcodeScanControllerProvider).lastOutcome,
        PosBarcodeScanOutcome.quantityIncreased);
    expect(container.read(posBarcodeScanControllerProvider).pendingCount, 0);
  });

  test('rapid different scans preserve FIFO order', () async {
    final gateway = _FakeGateway(delay: const Duration(milliseconds: 5));
    final container = _container(gateway: gateway);
    addTearDown(container.dispose);

    final controller =
        container.read(posBarcodeScanControllerProvider.notifier);
    controller.enqueue('A111');
    controller.enqueue('B222');
    await _waitForDrain(container);

    expect(gateway.barcodes, ['A111', 'B222']);
    expect(gateway.maximumConcurrent, 1);
  });

  test('queued scans emit exactly one ordered feedback event each', () async {
    final gateway = _FakeGateway(failFirst: true);
    var cartCalls = 0;
    final container = _container(
      gateway: gateway,
      cartAdd: (_, __) {
        cartCalls++;
        return cartCalls == 1
            ? PosCartMutationResult.added
            : PosCartMutationResult.quantityIncreased;
      },
    );
    addTearDown(container.dispose);
    final events = <PosBarcodeScanFeedbackEvent>[];
    final subscription = container.listen(
      posBarcodeScanControllerProvider.select((state) => state.feedbackEvent),
      (_, event) {
        if (event != null) events.add(event);
      },
    );
    addTearDown(subscription.close);

    final controller =
        container.read(posBarcodeScanControllerProvider.notifier);
    controller.enqueue('A111');
    controller.enqueue('B222');
    controller.enqueue('C333');
    await _waitForDrain(container);

    expect(events.map((event) => event.id), [1, 2, 3]);
    expect(events.map((event) => event.barcode), ['A111', 'B222', 'C333']);
    expect(events.map((event) => event.outcome), [
      PosBarcodeScanOutcome.barcodeNotFound,
      PosBarcodeScanOutcome.added,
      PosBarcodeScanOutcome.quantityIncreased,
    ]);
    expect(events.last.productName, 'Team Jersey');
    expect(events.last.variantName, 'Blue');
    expect(events.last.requestedQuantity, 2);
  });

  test('queue continues after API failure and cart rejection', () async {
    final gateway = _FakeGateway(failFirst: true);
    var cartCalls = 0;
    final container = _container(
      gateway: gateway,
      cartAdd: (_, __) {
        cartCalls++;
        return cartCalls == 1
            ? PosCartMutationResult.insufficientStock
            : PosCartMutationResult.added;
      },
    );
    addTearDown(container.dispose);

    final controller =
        container.read(posBarcodeScanControllerProvider.notifier);
    controller.enqueue('FAIL');
    controller.enqueue('REJECT');
    controller.enqueue('GOOD');
    await _waitForDrain(container);

    expect(gateway.barcodes, ['FAIL', 'REJECT', 'GOOD']);
    expect(cartCalls, 2);
    expect(container.read(posBarcodeScanControllerProvider).lastOutcome,
        PosBarcodeScanOutcome.added);
  });

  test('missing device prevents API call', () async {
    final gateway = _FakeGateway();
    final container = _container(gateway: gateway, deviceId: null);
    addTearDown(container.dispose);

    container.read(posBarcodeScanControllerProvider.notifier).enqueue('1234');
    await _waitForDrain(container);

    expect(gateway.barcodes, isEmpty);
    expect(container.read(posBarcodeScanControllerProvider).lastOutcome,
        PosBarcodeScanOutcome.invalidDevice);
  });

  test('missing authenticated session prevents API call', () async {
    final gateway = _FakeGateway();
    final container = ProviderContainer(overrides: [
      posBarcodeLookupGatewayProvider.overrideWithValue(gateway),
      posBarcodePrerequisitesProvider.overrideWithValue(() async =>
          const PosBarcodePrerequisiteResult.failure(
              PosBarcodeScanOutcome.authenticationRequired)),
    ]);
    container.listen(posBarcodeScanControllerProvider, (_, __) {},
        fireImmediately: true);
    addTearDown(container.dispose);

    container.read(posBarcodeScanControllerProvider.notifier).enqueue('1234');
    await _waitForDrain(container);

    expect(gateway.barcodes, isEmpty);
    expect(container.read(posBarcodeScanControllerProvider).lastOutcome,
        PosBarcodeScanOutcome.authenticationRequired);
  });

  test('stable API and network errors map to typed outcomes', () async {
    for (final entry in <int?, PosBarcodeScanOutcome>{
      404: PosBarcodeScanOutcome.barcodeNotFound,
      409: PosBarcodeScanOutcome.barcodeAmbiguous,
      422: PosBarcodeScanOutcome.productUnavailable,
      null: PosBarcodeScanOutcome.networkFailure,
    }.entries) {
      final gateway = _ErrorGateway(entry.key);
      final container = _container(gateway: gateway);
      container.read(posBarcodeScanControllerProvider.notifier).enqueue('1234');
      await _waitForDrain(container);
      expect(container.read(posBarcodeScanControllerProvider).lastOutcome,
          entry.value);
      container.dispose();
    }
  });

  test('controller disposal prevents delayed lookup from mutating cart',
      () async {
    final gateway = _CompleterGateway();
    var cartCalls = 0;
    final container = _container(
      gateway: gateway,
      cartAdd: (_, __) {
        cartCalls++;
        return PosCartMutationResult.added;
      },
    );
    container.read(posBarcodeScanControllerProvider.notifier).enqueue('1234');
    await Future<void>.delayed(Duration.zero);

    container.dispose();
    gateway.completer.complete(_result('1234'));
    await Future<void>.delayed(Duration.zero);

    expect(cartCalls, 0);
  });
}

ProviderContainer _container({
  required PosBarcodeLookupGateway gateway,
  String? deviceId = 'device-1',
  PosBarcodeCartAdd? cartAdd,
}) {
  final container = ProviderContainer(overrides: [
    posBarcodeLookupGatewayProvider.overrideWithValue(gateway),
    posBarcodePrerequisitesProvider.overrideWithValue(() async =>
        deviceId == null
            ? const PosBarcodePrerequisiteResult.failure(
                PosBarcodeScanOutcome.invalidDevice)
            : PosBarcodePrerequisiteResult.success(deviceId)),
    if (cartAdd != null) posBarcodeCartAddProvider.overrideWithValue(cartAdd),
  ]);
  container.listen(posBarcodeScanControllerProvider, (_, __) {},
      fireImmediately: true);
  return container;
}

Future<void> _waitForDrain(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    final state = container.read(posBarcodeScanControllerProvider);
    if (!state.isProcessing && state.pendingCount == 0) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('Barcode queue did not drain.');
}

class _FakeGateway implements PosBarcodeLookupGateway {
  _FakeGateway({this.delay = Duration.zero, this.failFirst = false});

  final Duration delay;
  final bool failFirst;
  final List<String> barcodes = [];
  int _concurrent = 0;
  int maximumConcurrent = 0;

  @override
  Future<PosBarcodeLookupResult> getProductByBarcode({
    required String deviceId,
    required String barcode,
  }) async {
    barcodes.add(barcode);
    _concurrent++;
    maximumConcurrent =
        maximumConcurrent < _concurrent ? _concurrent : maximumConcurrent;
    try {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (failFirst && barcodes.length == 1) {
        throw DioException(
          requestOptions: RequestOptions(path: '/barcode'),
          response: Response(
            requestOptions: RequestOptions(path: '/barcode'),
            statusCode: 404,
            data: {'code': 'pos_barcode.not_found'},
          ),
        );
      }
      return _result(barcode);
    } finally {
      _concurrent--;
    }
  }
}

class _ErrorGateway implements PosBarcodeLookupGateway {
  _ErrorGateway(this.status);
  final int? status;

  @override
  Future<PosBarcodeLookupResult> getProductByBarcode({
    required String deviceId,
    required String barcode,
  }) {
    final options = RequestOptions(path: '/barcode');
    throw DioException(
      requestOptions: options,
      type: status == null
          ? DioExceptionType.connectionError
          : DioExceptionType.badResponse,
      response: status == null
          ? null
          : Response(requestOptions: options, statusCode: status),
    );
  }
}

class _CompleterGateway implements PosBarcodeLookupGateway {
  final completer = Completer<PosBarcodeLookupResult>();

  @override
  Future<PosBarcodeLookupResult> getProductByBarcode({
    required String deviceId,
    required String barcode,
  }) =>
      completer.future;
}

PosBarcodeLookupResult _result(String barcode) => PosBarcodeLookupResult(
      productId: 'product-1',
      variantId: 'variant-1',
      barcode: barcode,
      barcodeType: 'CODE128',
      productName: 'Team Jersey',
      variantName: 'Blue',
      sku: 'SKU-1',
      quantityPerScan: 2,
      price: 2500,
      availableQuantity: 20,
      stockStatus: 'InStock',
    );

class _PipelineHarness extends ConsumerWidget {
  const _PipelineHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(posBarcodeScanControllerProvider);
    return PosBarcodeScannerListener(
      onBarcodeScanned:
          ref.read(posBarcodeScanControllerProvider.notifier).enqueue,
      child: const SizedBox(),
    );
  }
}

LogicalKeyboardKey _digitKey(String digit) => <String, LogicalKeyboardKey>{
      '0': LogicalKeyboardKey.digit0,
      '1': LogicalKeyboardKey.digit1,
      '2': LogicalKeyboardKey.digit2,
      '3': LogicalKeyboardKey.digit3,
      '4': LogicalKeyboardKey.digit4,
      '5': LogicalKeyboardKey.digit5,
      '6': LogicalKeyboardKey.digit6,
      '7': LogicalKeyboardKey.digit7,
      '8': LogicalKeyboardKey.digit8,
      '9': LogicalKeyboardKey.digit9,
    }[digit]!;
