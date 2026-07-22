import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/data/datasources/pos_barcode_remote_datasource.dart';
import '../../../cart/domain/entities/pos_resolved_sale_item.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../cart/presentation/providers/pos_resolved_variant_cart_action.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';

final posBarcodeLookupGatewayProvider = Provider<PosBarcodeLookupGateway>(
  (ref) => PosBarcodeRemoteDatasource(ref.watch(appDioProvider)),
);

typedef PosBarcodeCartAdd = PosCartMutationResult Function(
  PosResolvedSaleItem item,
  int requestedQuantity,
);

final posBarcodeCartAddProvider = Provider<PosBarcodeCartAdd>((ref) {
  return (item, requestedQuantity) =>
      ref.read(posResolvedVariantCartActionProvider).add(
            item,
            requestedQuantity: requestedQuantity,
          );
});

typedef PosBarcodePrerequisites = Future<PosBarcodePrerequisiteResult>
    Function();

final posBarcodePrerequisitesProvider =
    Provider<PosBarcodePrerequisites>((ref) {
  return () async {
    final dio = ref.read(appDioProvider);
    final session =
        await ref.read(authSessionProvider.notifier).ensureFreshSession(dio);
    if (session == null || !session.isAuthenticated) {
      return const PosBarcodePrerequisiteResult.failure(
        PosBarcodeScanOutcome.authenticationRequired,
      );
    }
    await ref.read(deviceActivationProvider.notifier).ensureHydrated();
    final device = ref.read(deviceActivationProvider).deviceContext;
    if (device == null || !device.isTrusted || device.deviceId.trim().isEmpty) {
      return const PosBarcodePrerequisiteResult.failure(
        PosBarcodeScanOutcome.invalidDevice,
      );
    }
    return PosBarcodePrerequisiteResult.success(device.deviceId.trim());
  };
});

final posBarcodeScanControllerProvider =
    AutoDisposeNotifierProvider<PosBarcodeScanController, PosBarcodeScanState>(
        PosBarcodeScanController.new);

class PosBarcodeScanController
    extends AutoDisposeNotifier<PosBarcodeScanState> {
  final Queue<String> _queue = Queue<String>();
  bool _draining = false;
  bool _disposed = false;
  int _feedbackSequence = 0;

  @override
  PosBarcodeScanState build() {
    ref.onDispose(() {
      _disposed = true;
      _queue.clear();
    });
    return const PosBarcodeScanState();
  }

  void enqueue(String barcode) {
    if (_disposed) return;
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(lastOutcome: PosBarcodeScanOutcome.invalidBarcode);
      return;
    }
    _queue.add(normalized);
    state = state.copyWith(pendingCount: _queue.length);
    _drain();
  }

  Future<void> _drain() async {
    if (_draining || _disposed) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty && !_disposed) {
        final barcode = _queue.removeFirst();
        state = state.copyWith(
          isProcessing: true,
          currentBarcode: barcode,
          pendingCount: _queue.length,
          clearCurrentBarcode: false,
        );
        final result = await _process(barcode);
        if (!_disposed) {
          state = state.copyWith(
            lastOutcome: result.outcome,
            feedbackEvent: PosBarcodeScanFeedbackEvent(
              id: ++_feedbackSequence,
              outcome: result.outcome,
              barcode: barcode,
              productName: result.productName,
              variantName: result.variantName,
              requestedQuantity: result.requestedQuantity,
            ),
          );
        }
      }
    } finally {
      _draining = false;
      if (!_disposed) {
        state = state.copyWith(
          isProcessing: false,
          pendingCount: _queue.length,
          clearCurrentBarcode: true,
        );
      }
    }
  }

  Future<_PosBarcodeProcessResult> _process(String barcode) async {
    try {
      final prerequisites = await ref.read(posBarcodePrerequisitesProvider)();
      if (prerequisites.error case final error?) {
        return _PosBarcodeProcessResult(error);
      }
      final deviceId = prerequisites.deviceId!;
      final result =
          await ref.read(posBarcodeLookupGatewayProvider).getProductByBarcode(
                deviceId: deviceId,
                barcode: barcode,
              );
      if (_disposed) {
        return const _PosBarcodeProcessResult(PosBarcodeScanOutcome.cancelled);
      }
      final cartResult = ref.read(posBarcodeCartAddProvider)(
        result.toResolvedSaleItem(),
        result.quantityPerScan,
      );
      return _PosBarcodeProcessResult(
        _mapCartResult(cartResult),
        productName: result.productName,
        variantName: result.variantName,
        requestedQuantity: result.quantityPerScan,
      );
    } on DioException catch (error) {
      return _PosBarcodeProcessResult(_mapDioError(error));
    } on FormatException {
      return const _PosBarcodeProcessResult(
          PosBarcodeScanOutcome.unexpectedFailure);
    } catch (_) {
      return const _PosBarcodeProcessResult(
          PosBarcodeScanOutcome.unexpectedFailure);
    }
  }
}

PosBarcodeScanOutcome _mapCartResult(PosCartMutationResult result) =>
    switch (result) {
      PosCartMutationResult.added => PosBarcodeScanOutcome.added,
      PosCartMutationResult.quantityIncreased =>
        PosBarcodeScanOutcome.quantityIncreased,
      PosCartMutationResult.invalidQuantity =>
        PosBarcodeScanOutcome.invalidBarcode,
      PosCartMutationResult.outOfStock => PosBarcodeScanOutcome.outOfStock,
      PosCartMutationResult.insufficientStock =>
        PosBarcodeScanOutcome.insufficientStock,
      PosCartMutationResult.productUnavailable =>
        PosBarcodeScanOutcome.productUnavailable,
      PosCartMutationResult.variantUnavailable =>
        PosBarcodeScanOutcome.variantUnavailable,
      PosCartMutationResult.priceUnavailable =>
        PosBarcodeScanOutcome.priceUnavailable,
    };

PosBarcodeScanOutcome _mapDioError(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code']?.toString() : null;
  return switch (code) {
    'pos_barcode.not_found' => PosBarcodeScanOutcome.barcodeNotFound,
    'pos_barcode.ambiguous' => PosBarcodeScanOutcome.barcodeAmbiguous,
    'pos_product.unavailable' => PosBarcodeScanOutcome.productUnavailable,
    'pos_variant.unavailable' => PosBarcodeScanOutcome.variantUnavailable,
    'pos_price.unavailable' => PosBarcodeScanOutcome.priceUnavailable,
    'pos_device.invalid' => PosBarcodeScanOutcome.invalidDevice,
    _ => switch (error.response?.statusCode) {
        401 => PosBarcodeScanOutcome.authenticationRequired,
        403 => PosBarcodeScanOutcome.permissionDenied,
        404 => PosBarcodeScanOutcome.barcodeNotFound,
        409 => PosBarcodeScanOutcome.barcodeAmbiguous,
        422 => PosBarcodeScanOutcome.productUnavailable,
        null => PosBarcodeScanOutcome.networkFailure,
        _ => PosBarcodeScanOutcome.unexpectedFailure,
      },
  };
}

class PosBarcodeScanState {
  const PosBarcodeScanState({
    this.isProcessing = false,
    this.currentBarcode,
    this.pendingCount = 0,
    this.lastOutcome,
    this.feedbackEvent,
  });

  final bool isProcessing;
  final String? currentBarcode;
  final int pendingCount;
  final PosBarcodeScanOutcome? lastOutcome;
  final PosBarcodeScanFeedbackEvent? feedbackEvent;

  PosBarcodeScanState copyWith({
    bool? isProcessing,
    String? currentBarcode,
    bool clearCurrentBarcode = false,
    int? pendingCount,
    PosBarcodeScanOutcome? lastOutcome,
    PosBarcodeScanFeedbackEvent? feedbackEvent,
  }) =>
      PosBarcodeScanState(
        isProcessing: isProcessing ?? this.isProcessing,
        currentBarcode:
            clearCurrentBarcode ? null : currentBarcode ?? this.currentBarcode,
        pendingCount: pendingCount ?? this.pendingCount,
        lastOutcome: lastOutcome ?? this.lastOutcome,
        feedbackEvent: feedbackEvent ?? this.feedbackEvent,
      );
}

class PosBarcodeScanFeedbackEvent {
  const PosBarcodeScanFeedbackEvent({
    required this.id,
    required this.outcome,
    required this.barcode,
    this.productName,
    this.variantName,
    this.requestedQuantity,
  });

  final int id;
  final PosBarcodeScanOutcome outcome;
  final String barcode;
  final String? productName;
  final String? variantName;
  final int? requestedQuantity;
}

class _PosBarcodeProcessResult {
  const _PosBarcodeProcessResult(
    this.outcome, {
    this.productName,
    this.variantName,
    this.requestedQuantity,
  });

  final PosBarcodeScanOutcome outcome;
  final String? productName;
  final String? variantName;
  final int? requestedQuantity;
}

enum PosBarcodeScanOutcome {
  added,
  quantityIncreased,
  barcodeNotFound,
  barcodeAmbiguous,
  invalidBarcode,
  invalidDevice,
  authenticationRequired,
  permissionDenied,
  productUnavailable,
  variantUnavailable,
  priceUnavailable,
  outOfStock,
  insufficientStock,
  networkFailure,
  unexpectedFailure,
  cancelled,
}

class PosBarcodePrerequisiteResult {
  const PosBarcodePrerequisiteResult.success(this.deviceId) : error = null;
  const PosBarcodePrerequisiteResult.failure(this.error) : deviceId = null;

  final String? deviceId;
  final PosBarcodeScanOutcome? error;
}
