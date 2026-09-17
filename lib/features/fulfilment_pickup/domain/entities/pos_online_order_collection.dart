enum PosCollectionFailureReason {
  qrInvalid,
  qrExpired,
  wrongOutlet,
  notReady,
  cancelled,
  alreadyCollected,
  missingGraph,
  paymentRequired,
  permissionDenied,
  concurrencyConflict,
  notFound,
  unknown;

  static PosCollectionFailureReason fromErrorCode(String? code) {
    return switch (code) {
      'online_orders.collection.qr_invalid' => qrInvalid,
      'online_orders.collection.qr_expired' => qrExpired,
      'online_orders.collection.wrong_outlet' => wrongOutlet,
      'online_orders.collection.not_ready' => notReady,
      'online_orders.collection.cancelled' => cancelled,
      'online_orders.collection.already_collected' => alreadyCollected,
      'online_orders.collection.missing_graph' => missingGraph,
      'online_orders.collection.payment_required' => paymentRequired,
      'online_orders.permission_denied' => permissionDenied,
      'online_orders.fulfillment_conflict' ||
      'online_orders.concurrency_conflict' =>
        concurrencyConflict,
      'online_orders.not_found' => notFound,
      _ => unknown,
    };
  }

  String get safeMessage => switch (this) {
        qrInvalid => 'This collection QR is not valid.',
        qrExpired =>
          'This collection QR has expired. Ask the customer for a new code.',
        wrongOutlet => 'This order belongs to a different outlet.',
        notReady => 'This order is not ready for collection yet.',
        cancelled => 'This order has been cancelled.',
        alreadyCollected => 'This order has already been collected.',
        missingGraph => 'Collection data is incomplete for this order.',
        paymentRequired =>
          'Outstanding balance must be settled before collection.',
        permissionDenied =>
          'You do not have permission to perform this collection action.',
        concurrencyConflict => 'This order changed. Refresh and try again.',
        notFound => 'This online order is no longer available.',
        unknown => 'Unable to validate this collection QR. Try again.',
      };
}

class PosCollectionItem {
  const PosCollectionItem({
    required this.productName,
    required this.quantityPacked,
  });

  final String productName;
  final double quantityPacked;

  factory PosCollectionItem.fromJson(Map<String, dynamic> json) =>
      PosCollectionItem(
        productName: (json['productName'] ?? '').toString(),
        quantityPacked: _decimal(json['quantityPacked']),
      );
}

class PosCollectionValidationResult {
  const PosCollectionValidationResult({
    required this.orderId,
    required this.orderNumber,
    this.customerName,
    this.customerPhone,
    required this.outletId,
    this.outletName,
    this.collectionWindowStart,
    this.collectionWindowEnd,
    required this.fulfillmentStatus,
    required this.pickupStatus,
    this.readyAt,
    this.collectedAt,
    required this.paymentStatus,
    required this.currency,
    required this.total,
    required this.paidAmount,
    required this.balanceDue,
    required this.canCollect,
    required this.canTakePayment,
    required this.expectedVersion,
    required this.pickupNumber,
    this.items = const [],
  });

  final String orderId;
  final String orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String outletId;
  final String? outletName;
  final DateTime? collectionWindowStart;
  final DateTime? collectionWindowEnd;
  final String fulfillmentStatus;
  final String pickupStatus;
  final DateTime? readyAt;
  final DateTime? collectedAt;
  final String paymentStatus;
  final String currency;
  final double total;
  final double paidAmount;
  final double balanceDue;
  final bool canCollect;
  final bool canTakePayment;
  final int expectedVersion;
  final String pickupNumber;
  final List<PosCollectionItem> items;

  /// Whole currency units used by the shared POS checkout screens.
  int get balanceDueCheckoutAmount => balanceDue.round();

  PosCollectionValidationResult withPaymentSettled() =>
      PosCollectionValidationResult(
        orderId: orderId,
        orderNumber: orderNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        outletId: outletId,
        outletName: outletName,
        collectionWindowStart: collectionWindowStart,
        collectionWindowEnd: collectionWindowEnd,
        fulfillmentStatus: fulfillmentStatus,
        pickupStatus: pickupStatus,
        readyAt: readyAt,
        collectedAt: collectedAt,
        paymentStatus: 'PAID',
        currency: currency,
        total: total,
        paidAmount: total,
        balanceDue: 0,
        canCollect: true,
        canTakePayment: false,
        expectedVersion: expectedVersion,
        pickupNumber: pickupNumber,
        items: items,
      );

  factory PosCollectionValidationResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
                (e) => PosCollectionItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <PosCollectionItem>[];

    return PosCollectionValidationResult(
      orderId: (json['orderId'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      customerName: _nullableString(json['customerName']),
      customerPhone: _nullableString(json['customerPhone']),
      outletId: (json['outletId'] ?? '').toString(),
      outletName: _nullableString(json['outletName']),
      collectionWindowStart: _date(json['collectionWindowStart']),
      collectionWindowEnd: _date(json['collectionWindowEnd']),
      fulfillmentStatus: (json['fulfillmentStatus'] ?? '').toString(),
      pickupStatus: (json['pickupStatus'] ?? '').toString(),
      readyAt: _date(json['readyAt']),
      collectedAt: _date(json['collectedAt']),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      total: _decimal(json['total']),
      paidAmount: _decimal(json['paidAmount']),
      balanceDue: _decimal(json['balanceDue']),
      canCollect: json['canCollect'] == true,
      canTakePayment: json['canTakePayment'] == true,
      expectedVersion: _integer(json['expectedVersion']),
      pickupNumber: (json['pickupNumber'] ?? '').toString(),
      items: items,
    );
  }
}

class PosCollectionCompleteResult {
  const PosCollectionCompleteResult({
    required this.orderId,
    required this.orderNumber,
    required this.pickupStatus,
    required this.fulfillmentStatus,
    required this.salesOrderStatus,
    required this.salesFulfillmentStatus,
    this.collectedAt,
    this.fulfilledAt,
    this.completedAt,
    required this.fulfillmentVersion,
    required this.alreadyCollected,
  });

  final String orderId;
  final String orderNumber;
  final String pickupStatus;
  final String fulfillmentStatus;
  final String salesOrderStatus;
  final String salesFulfillmentStatus;
  final DateTime? collectedAt;
  final DateTime? fulfilledAt;
  final DateTime? completedAt;
  final int fulfillmentVersion;
  final bool alreadyCollected;

  factory PosCollectionCompleteResult.fromJson(Map<String, dynamic> json) =>
      PosCollectionCompleteResult(
        orderId: (json['orderId'] ?? '').toString(),
        orderNumber: (json['orderNumber'] ?? '').toString(),
        pickupStatus: (json['pickupStatus'] ?? '').toString(),
        fulfillmentStatus: (json['fulfillmentStatus'] ?? '').toString(),
        salesOrderStatus: (json['salesOrderStatus'] ?? '').toString(),
        salesFulfillmentStatus:
            (json['salesFulfillmentStatus'] ?? '').toString(),
        collectedAt: _date(json['collectedAt']),
        fulfilledAt: _date(json['fulfilledAt']),
        completedAt: _date(json['completedAt']),
        fulfillmentVersion: _integer(json['fulfillmentVersion']),
        alreadyCollected: json['alreadyCollected'] == true,
      );
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double _decimal(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
