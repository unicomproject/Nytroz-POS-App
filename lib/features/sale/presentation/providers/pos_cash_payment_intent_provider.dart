import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CashPaymentIntentPhase {
  draft,
  inFlight,
  knownRejected,
  unknown,
  succeeded
}

String? cashPaymentSafetyRedirect(String path, CashPaymentIntentPhase? phase,
    {bool cartCompleted = false}) {
  const cash = '/pos/new-sale/payment/cash';
  const success = '$cash/success';
  // Click & Collect balance settle navigates back to collection handover.
  if (path.startsWith('/pos/online-orders/collection')) {
    return null;
  }
  if (cartCompleted || phase == CashPaymentIntentPhase.succeeded) {
    return path == success || path.startsWith('$success/') ? null : success;
  }
  if (phase == CashPaymentIntentPhase.inFlight ||
      phase == CashPaymentIntentPhase.unknown) {
    return path == cash ? null : cash;
  }
  return null;
}

class CashPaymentIntent {
  const CashPaymentIntent({
    required this.key,
    required this.saleIdentity,
    required this.phase,
    this.dispatchedFingerprint,
  });

  final String key;
  final String saleIdentity;
  final CashPaymentIntentPhase phase;
  final String? dispatchedFingerprint;

  CashPaymentIntent copyWith({
    CashPaymentIntentPhase? phase,
    String? dispatchedFingerprint,
  }) =>
      CashPaymentIntent(
        key: key,
        saleIdentity: saleIdentity,
        phase: phase ?? this.phase,
        dispatchedFingerprint:
            dispatchedFingerprint ?? this.dispatchedFingerprint,
      );
}

class CashPaymentIntentNotifier extends StateNotifier<CashPaymentIntent?> {
  CashPaymentIntentNotifier({String Function()? keyFactory})
      : _keyFactory = keyFactory ?? _defaultKeyFactory,
        super(null);

  final String Function() _keyFactory;
  String Function() get keyFactory => _keyFactory;

  CashPaymentIntent open(String saleIdentity) {
    final current = state;
    if (current == null ||
        (current.saleIdentity != saleIdentity &&
            current.phase == CashPaymentIntentPhase.draft)) {
      return startNew(saleIdentity);
    }
    return current;
  }

  CashPaymentIntent startNew(String saleIdentity) {
    final current = state;
    if (current?.phase == CashPaymentIntentPhase.inFlight ||
        current?.phase == CashPaymentIntentPhase.unknown ||
        current?.phase == CashPaymentIntentPhase.succeeded) {
      throw StateError('Unresolved Cash payment intent must be reconciled.');
    }
    final next = CashPaymentIntent(
      key: _keyFactory(),
      saleIdentity: saleIdentity,
      phase: CashPaymentIntentPhase.draft,
    );
    state = next;
    return next;
  }

  CashPaymentIntent beginSubmission({
    required String saleIdentity,
    required String requestFingerprint,
  }) {
    var current = open(saleIdentity);
    if (current.phase == CashPaymentIntentPhase.succeeded) {
      throw StateError('This sale is already completed. Start New Sale first.');
    }
    if (current.phase == CashPaymentIntentPhase.knownRejected) {
      throw StateError('Start a new Cash payment attempt before submitting.');
    }
    if (current.phase == CashPaymentIntentPhase.unknown) {
      throw StateError('Unknown Cash payment result must be reconciled.');
    }
    if (current.phase == CashPaymentIntentPhase.inFlight) {
      if (current.dispatchedFingerprint != requestFingerprint) {
        throw StateError('Cash payment request changed while in flight.');
      }
      throw StateError('Cash payment is already being submitted.');
    }
    current = current.copyWith(
      phase: CashPaymentIntentPhase.inFlight,
      dispatchedFingerprint: requestFingerprint,
    );
    state = current;
    return current;
  }

  void markKnownRejected() => _transition(CashPaymentIntentPhase.knownRejected);
  void markUnknown() => _transition(CashPaymentIntentPhase.unknown);
  void markSucceeded() => _transition(CashPaymentIntentPhase.succeeded);

  /// Clears intent without New Sale reconciliation (e.g. Click & Collect settle).
  void clear() => state = null;

  void _transition(CashPaymentIntentPhase phase) {
    final current = state;
    if (current != null) state = current.copyWith(phase: phase);
  }

  static String _defaultKeyFactory() {
    final random = Random.secure();
    final nonce = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return 'pos-${DateTime.now().microsecondsSinceEpoch}-$nonce';
  }
}

final posCashPaymentIntentProvider =
    StateNotifierProvider<CashPaymentIntentNotifier, CashPaymentIntent?>(
  (ref) => CashPaymentIntentNotifier(),
);
