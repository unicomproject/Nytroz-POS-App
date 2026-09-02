class PosOnlineOrderSummary {
  const PosOnlineOrderSummary({
    required this.total,
    required this.pending,
    required this.preparing,
    required this.ready,
    required this.overdue,
    required this.newOrders,
    required this.collected,
    required this.cancelled,
  });

  final int total;
  final int pending;
  final int preparing;
  final int ready;
  final int overdue;
  final int newOrders;
  final int collected;
  final int cancelled;

  factory PosOnlineOrderSummary.fromJson(Map<String, dynamic> json) {
    final newCount = _integer(json['newCount']);
    final preparingCount = _integer(json['preparingCount']);
    final readyCount = _integer(json['readyCount']);
    final delayedCount = _integer(json['delayedCount']);
    final collectedCount = _integer(json['collectedCount']);
    final cancelledCount = _integer(json['cancelledCount']);

    return PosOnlineOrderSummary(
      total: newCount +
          preparingCount +
          readyCount +
          delayedCount +
          collectedCount +
          cancelledCount,
      pending: newCount,
      preparing: preparingCount,
      ready: readyCount,
      overdue: delayedCount,
      newOrders: newCount,
      collected: collectedCount,
      cancelled: cancelledCount,
    );
  }
}

enum PosOnlineOrderSort {
  collectionAsc('collectionTime', 'asc'),
  collectionDesc('collectionTime', 'desc'),
  newest('placedAt', 'desc'),
  oldest('placedAt', 'asc');

  const PosOnlineOrderSort(this.apiValue, this.direction);

  final String apiValue;
  final String direction;
  String get label => direction == 'asc'
      ? 'Collection time (earliest)'
      : 'Collection time (latest)';
}

class PosOnlineOrdersQuery {
  const PosOnlineOrdersQuery({
    required this.outletId,
    this.search = '',
    this.status,
    this.sort = PosOnlineOrderSort.collectionAsc,
    this.page = 1,
    this.pageSize = 20,
  });

  final String outletId;
  final String search;
  final String? status;
  final PosOnlineOrderSort sort;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
        'outletId': outletId,
        'page': page,
        'pageSize': pageSize,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status?.trim().isNotEmpty ?? false) 'status': status!.trim(),
        'sortBy': sort.apiValue,
        'sortDirection': sort.direction,
      };
}

class PosOnlineOrderProductPreview {
  const PosOnlineOrderProductPreview({
    required this.productId,
    required this.productName,
    this.productVariantId,
    this.imageUrl,
    this.altText,
  });

  final String productId;
  final String? productVariantId;
  final String productName;
  final String? imageUrl;
  final String? altText;

  factory PosOnlineOrderProductPreview.fromJson(Map<String, dynamic> json) =>
      PosOnlineOrderProductPreview(
        productId: _text(json['productId']),
        productVariantId: _optionalText(json['productVariantId']),
        productName: _text(json['productName']),
        imageUrl: _optionalText(json['imageUrl']),
        altText: _optionalText(json['altText']),
      );
}

class PosOnlineOrder {
  const PosOnlineOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.statusLabel,
    required this.paymentStatus,
    required this.currencyCode,
    required this.totalAmount,
    required this.lineCount,
    this.unitCount = 0,
    this.productPreviews = const [],
    this.remainingPreviewCount = 0,
    this.externalOrderReference,
    this.customerPhone,
    this.collectionAt,
    this.collectionEndAt,
    this.collectionTimezone,
    this.placedAt,
    this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final String? externalOrderReference;
  final String customerName;
  final String? customerPhone;
  final DateTime? collectionAt;
  final DateTime? collectionEndAt;
  final String? collectionTimezone;
  final String status;
  final String statusLabel;
  final String paymentStatus;
  final String currencyCode;
  final double totalAmount;
  final int lineCount;
  final int unitCount;
  final List<PosOnlineOrderProductPreview> productPreviews;
  final int remainingPreviewCount;
  final DateTime? placedAt;
  final DateTime? updatedAt;

  factory PosOnlineOrder.fromJson(Map<String, dynamic> json) => PosOnlineOrder(
        id: _text(json['id']),
        orderNumber: _text(json['orderNumber']),
        externalOrderReference: _optionalText(
          json['externalReference'] ?? json['externalOrderReference'],
        ),
        customerName: _text(json['customerName'], fallback: 'Walk-in Customer'),
        customerPhone: _optionalText(json['customerPhone']),
        collectionAt: _date(json['collectionStart'] ?? json['collectionAt']),
        collectionEndAt:
            _date(json['collectionEnd'] ?? json['collectionEndAt']),
        collectionTimezone: _optionalText(json['collectionTimezone']),
        status: _text(json['status']),
        statusLabel: _text(json['statusLabel']),
        paymentStatus: _text(json['paymentStatus']),
        currencyCode: _text(json['currencyCode'], fallback: 'LKR'),
        totalAmount: _decimal(json['totalAmount']),
        lineCount: _integer(json['itemCount'] ?? json['lineCount']),
        unitCount: _integer(json['unitCount']),
        productPreviews: (json['productPreviews'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => PosOnlineOrderProductPreview.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
        remainingPreviewCount: _integer(json['remainingPreviewCount']),
        placedAt: _date(json['placedAt']),
        updatedAt: _date(json['updatedAt']),
      );
}

class PosOnlineOrderLine {
  const PosOnlineOrderLine({
    required this.id,
    required this.lineNumber,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.pickedQuantity,
    required this.packedQuantity,
    this.variantName,
    this.sku,
    this.barcode,
    this.lineStatus,
    this.salesOrderLineId,
    this.fulfillmentOrderLineId,
    this.productId,
    this.productVariantId,
    this.imageUrl,
    this.altText,
    this.authoritativeRemainingQuantity,
  });

  final String id;
  final int lineNumber;
  final String productName;
  final String? variantName;
  final String? sku;
  final String? barcode;
  final String? lineStatus;
  final String? salesOrderLineId;
  final String? fulfillmentOrderLineId;
  final String? productId;
  final String? productVariantId;
  final String? imageUrl;
  final String? altText;
  final double? authoritativeRemainingQuantity;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final double pickedQuantity;
  final double packedQuantity;

  double get remainingQuantity =>
      authoritativeRemainingQuantity ??
      (quantity - pickedQuantity).clamp(0, quantity).toDouble();

  factory PosOnlineOrderLine.fromJson(Map<String, dynamic> json) =>
      PosOnlineOrderLine(
        id: _text(json['id']),
        lineNumber: _integer(json['lineNumber']),
        productName: _text(json['productName']),
        variantName: _optionalText(json['variantName']),
        sku: _optionalText(json['sku']),
        barcode: _optionalText(json['barcode']),
        lineStatus: _optionalText(json['lineStatus']),
        salesOrderLineId: _optionalText(json['salesOrderLineId']),
        fulfillmentOrderLineId: _optionalText(json['fulfillmentOrderLineId']),
        productId: _optionalText(json['productId']),
        productVariantId: _optionalText(json['productVariantId']),
        imageUrl: _optionalText(json['imageUrl']),
        altText: _optionalText(json['altText']),
        authoritativeRemainingQuantity: json['remainingQuantity'] == null
            ? null
            : _decimal(json['remainingQuantity']),
        quantity: _decimal(json['quantity']),
        unitPrice: _decimal(json['unitPrice']),
        lineTotal: _decimal(json['lineTotal']),
        pickedQuantity: _decimal(json['pickedQuantity']),
        packedQuantity: _decimal(json['packedQuantity']),
      );
}

class PosOnlineOrderDetail {
  const PosOnlineOrderDetail({
    required this.order,
    required this.outletName,
    required this.paymentStatus,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.charges,
    required this.paid,
    required this.balanceDue,
    required this.lines,
    this.customerPhone,
    this.customerEmail,
    this.customerNote,
    this.outletId,
    this.customerId,
    this.internalNote,
    this.fulfillmentOrderId,
    this.assignedToTenantUserId,
    this.placedAt,
    this.updatedAt,
    this.orderStatus,
    this.fulfillmentStatus,
    this.pickupStatus,
    this.salesChannel,
    this.customerClassification,
    this.pickupNumber,
    this.fulfillmentVersion,
    this.serverTime,
    this.backendItemCount,
    this.backendUnitCount,
  });

  final PosOnlineOrder order;
  final String outletName;
  final String paymentStatus;
  final double subtotal;
  final double discount;
  final double tax;
  final double charges;
  final double paid;
  final double balanceDue;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerNote;
  final String? outletId;
  final String? customerId;
  final String? internalNote;
  final String? fulfillmentOrderId;
  final String? assignedToTenantUserId;
  final DateTime? placedAt;
  final DateTime? updatedAt;
  final String? orderStatus;
  final String? fulfillmentStatus;
  final String? pickupStatus;
  final String? salesChannel;
  final String? customerClassification;
  final String? pickupNumber;
  final int? fulfillmentVersion;
  final DateTime? serverTime;
  final int? backendItemCount;
  final double? backendUnitCount;
  final List<PosOnlineOrderLine> lines;

  int get itemCount => backendItemCount ?? lines.length;
  double get unitCount =>
      backendUnitCount ??
      lines.fold<double>(0, (total, line) => total + line.quantity);

  factory PosOnlineOrderDetail.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List? ?? const [])
        .whereType<Map>()
        .map((item) =>
            PosOnlineOrderLine.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return PosOnlineOrderDetail(
      order: PosOnlineOrder(
        id: _text(json['id']),
        orderNumber: _text(json['orderNumber']),
        externalOrderReference: _optionalText(
          json['externalReference'] ?? json['externalOrderReference'],
        ),
        customerName: _text(json['customerName'], fallback: 'Walk-in Customer'),
        customerPhone: _optionalText(json['customerPhone']),
        collectionAt: _date(json['collectionStart'] ?? json['collectionAt']),
        collectionEndAt:
            _date(json['collectionEnd'] ?? json['collectionEndAt']),
        collectionTimezone: _optionalText(json['collectionTimezone']),
        status: _text(json['status']),
        statusLabel: _text(json['statusLabel']),
        paymentStatus: _text(json['paymentStatus']),
        currencyCode: _text(json['currencyCode'], fallback: 'LKR'),
        totalAmount: _decimal(json['totalAmount']),
        lineCount: lines.length,
        placedAt: _date(json['placedAt']),
        updatedAt: _date(json['updatedAt']),
      ),
      outletName: _text(json['outletName']),
      paymentStatus: _text(json['paymentStatus']),
      subtotal: _decimal(json['subtotalAmount'] ?? json['subtotal']),
      discount: _decimal(json['discountAmount'] ?? json['discount']),
      tax: _decimal(json['taxAmount'] ?? json['tax']),
      charges: _decimal(json['chargeAmount'] ?? json['charges']),
      paid: _decimal(json['paidAmount'] ?? json['paid']),
      balanceDue: _decimal(json['balanceDue']),
      customerPhone: _optionalText(json['customerPhone']),
      customerEmail: _optionalText(json['customerEmail']),
      customerNote: _optionalText(json['customerNote']),
      outletId: _optionalText(json['outletId']),
      customerId: _optionalText(json['customerId']),
      internalNote: _optionalText(json['internalNote']),
      fulfillmentOrderId: _optionalText(json['fulfillmentOrderId']),
      assignedToTenantUserId: _optionalText(json['assignedToTenantUserId']),
      placedAt: _date(json['placedAt']),
      updatedAt: _date(json['updatedAt']),
      orderStatus: _optionalText(json['orderStatus']),
      fulfillmentStatus: _optionalText(json['fulfillmentStatus']),
      pickupStatus: _optionalText(json['pickupStatus']),
      salesChannel: _optionalText(json['salesChannel']),
      customerClassification: _optionalText(json['customerClassification']),
      pickupNumber: _optionalText(json['pickupNumber']),
      fulfillmentVersion: json['fulfillmentVersion'] == null
          ? null
          : _integer(json['fulfillmentVersion']),
      serverTime: _date(json['serverTime']),
      backendItemCount:
          json['itemCount'] == null ? null : _integer(json['itemCount']),
      backendUnitCount:
          json['unitCount'] == null ? null : _decimal(json['unitCount']),
      lines: lines,
    );
  }
}

class PosOnlineOrderPage {
  const PosOnlineOrderPage({
    required this.items,
    required this.summary,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    this.serverTime,
  });

  final List<PosOnlineOrder> items;
  final PosOnlineOrderSummary summary;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final DateTime? serverTime;

  factory PosOnlineOrderPage.fromJson(Map<String, dynamic> json) =>
      PosOnlineOrderPage(
        items: (json['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) =>
                PosOnlineOrder.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        summary: PosOnlineOrderSummary.fromJson(
          Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
        ),
        page: _integer(json['page'], fallback: 1),
        pageSize: _integer(json['pageSize'], fallback: 20),
        totalCount: _integer(json['totalCount']),
        totalPages: _integer(json['totalPages']),
        serverTime: _date(json['serverTime']),
      );
}

class PosStartFulfillmentResult {
  const PosStartFulfillmentResult({
    required this.orderId,
    required this.fulfillmentOrderId,
    required this.status,
    required this.alreadyStarted,
    this.fulfillmentNumber,
    this.assignedToTenantUserId,
    this.startedAt,
    this.fulfillmentVersion,
  });

  final String orderId;
  final String fulfillmentOrderId;
  final String status;
  final bool alreadyStarted;
  final String? fulfillmentNumber;
  final String? assignedToTenantUserId;
  final DateTime? startedAt;
  final int? fulfillmentVersion;

  factory PosStartFulfillmentResult.fromJson(Map<String, dynamic> json) =>
      PosStartFulfillmentResult(
        orderId: _text(json['orderId']),
        fulfillmentOrderId: _text(json['fulfillmentOrderId']),
        status: _text(json['fulfillmentStatus'] ?? json['status']),
        alreadyStarted: json['alreadyStarted'] == true,
        fulfillmentNumber: _optionalText(json['fulfillmentNumber']),
        assignedToTenantUserId: _optionalText(json['assignedToTenantUserId']),
        startedAt: _date(json['startedAt']),
        fulfillmentVersion: json['fulfillmentVersion'] == null
            ? null
            : _integer(json['fulfillmentVersion']),
      );
}

class PosPickingLine {
  const PosPickingLine({
    required this.id,
    required this.lineNumber,
    required this.productName,
    required this.requestedQuantity,
    required this.pickedQuantity,
    required this.status,
    this.variantName,
    this.sku,
    this.barcode,
    this.locationCode,
    this.locationName,
    this.imageUrl,
    this.altText,
    this.hasReportedIssue = false,
  });

  final String id;
  final int lineNumber;
  final String productName;
  final String? variantName;
  final String? sku;
  final String? barcode;
  final double requestedQuantity;
  final double pickedQuantity;
  final String status;
  final String? locationCode;
  final String? locationName;
  final String? imageUrl;
  final String? altText;
  final bool hasReportedIssue;

  double get remainingQuantity => (requestedQuantity - pickedQuantity)
      .clamp(0, requestedQuantity)
      .toDouble();
  bool get isPicked => remainingQuantity == 0;

  factory PosPickingLine.fromJson(Map<String, dynamic> json) => PosPickingLine(
        id: _text(json['id']),
        lineNumber: _integer(json['lineNumber']),
        productName: _text(json['productName']),
        variantName: _optionalText(json['variantName']),
        sku: _optionalText(json['sku']),
        barcode: _optionalText(json['barcode']),
        requestedQuantity: _decimal(json['requestedQuantity']),
        pickedQuantity: _decimal(json['pickedQuantity']),
        status: _text(json['status']),
        locationCode: _optionalText(json['locationCode']),
        locationName: _optionalText(json['locationName']),
        imageUrl: _optionalText(json['imageUrl']),
        altText: _optionalText(json['altText']),
        hasReportedIssue: json['hasReportedIssue'] == true,
      );
}

class PosPickingNote {
  const PosPickingNote({
    required this.id,
    required this.note,
    required this.createdAt,
    required this.createdByTenantUserId,
    required this.createdByDisplayName,
  });

  final String id;
  final String note;
  final DateTime? createdAt;
  final String createdByTenantUserId;
  final String createdByDisplayName;

  factory PosPickingNote.fromJson(Map<String, dynamic> json) => PosPickingNote(
        id: _text(json['id']),
        note: _text(json['note']),
        createdAt: _date(json['createdAt']),
        createdByTenantUserId: _text(json['createdByTenantUserId']),
        createdByDisplayName: _text(json['createdByDisplayName']),
      );
}

class PosPickingOrder {
  const PosPickingOrder({
    required this.orderId,
    required this.orderNumber,
    required this.fulfillmentOrderId,
    required this.fulfillmentNumber,
    required this.status,
    required this.assignedToName,
    required this.customerName,
    required this.totalLines,
    required this.pickedLines,
    required this.lines,
    this.collectionAt,
    this.assignedToTenantUserId,
    this.totalUnits = 0,
    this.pickedUnits = 0,
    this.remainingUnits = 0,
    this.canPack = false,
    this.fulfillmentVersion = 0,
    this.serverTime,
    this.notes = const [],
  });

  final String orderId;
  final String orderNumber;
  final String fulfillmentOrderId;
  final String fulfillmentNumber;
  final String status;
  final String assignedToName;
  final String? assignedToTenantUserId;
  final String customerName;
  final DateTime? collectionAt;
  final int totalLines;
  final int pickedLines;
  final List<PosPickingLine> lines;
  final double totalUnits;
  final double pickedUnits;
  final double remainingUnits;
  final bool canPack;
  final int fulfillmentVersion;
  final DateTime? serverTime;
  final List<PosPickingNote> notes;
  bool get allPicked =>
      lines.isNotEmpty && lines.every((line) => line.isPicked);

  factory PosPickingOrder.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List? ?? const [])
        .whereType<Map>()
        .map((item) =>
            PosPickingLine.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final derivedTotal = lines.fold<double>(
        0, (total, line) => total + line.requestedQuantity);
    final derivedPicked = lines.fold<double>(
        0, (total, line) => total + line.pickedQuantity);
    return PosPickingOrder(
        orderId: _text(json['orderId']),
        orderNumber: _text(json['orderNumber']),
        fulfillmentOrderId: _text(json['fulfillmentOrderId']),
        fulfillmentNumber: _text(json['fulfillmentNumber']),
        status: _text(json['status']),
        assignedToName: _text(json['assignedToName']),
        assignedToTenantUserId: _optionalText(json['assignedToTenantUserId']),
        customerName: _text(json['customerName']),
        collectionAt: _date(json['collectionAt']),
        totalLines: _integer(json['totalLines']),
        pickedLines: _integer(json['pickedLines']),
        totalUnits: json['totalUnits'] == null
            ? derivedTotal
            : _decimal(json['totalUnits']),
        pickedUnits: json['pickedUnits'] == null
            ? derivedPicked
            : _decimal(json['pickedUnits']),
        remainingUnits: json['remainingUnits'] == null
            ? (derivedTotal - derivedPicked).clamp(0, derivedTotal).toDouble()
            : _decimal(json['remainingUnits']),
        canPack: json['canPack'] == true,
        fulfillmentVersion: _integer(json['fulfillmentVersion']),
        serverTime: _date(json['serverTime']),
        notes: (json['notes'] as List? ?? const [])
            .whereType<Map>()
            .map((item) =>
                PosPickingNote.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        lines: lines,
      );
  }
}

class PosFulfillmentCommandResult {
  const PosFulfillmentCommandResult({
    required this.orderId,
    required this.status,
    required this.totalLines,
    required this.completedLines,
    this.packageNumber,
    this.fulfillmentOrderId,
    this.updatedAt,
    this.canPack = false,
    this.fulfillmentVersion = 0,
  });
  final String orderId;
  final String status;
  final int totalLines;
  final int completedLines;
  final String? packageNumber;
  final String? fulfillmentOrderId;
  final DateTime? updatedAt;
  final bool canPack;
  final int fulfillmentVersion;

  factory PosFulfillmentCommandResult.fromJson(Map<String, dynamic> json) =>
      PosFulfillmentCommandResult(
        orderId: _text(json['orderId']),
        status: _text(json['status']),
        totalLines: _integer(json['totalLines']),
        completedLines: _integer(json['completedLines']),
        packageNumber: _optionalText(json['packageNumber']),
        fulfillmentOrderId: _optionalText(json['fulfillmentOrderId']),
        updatedAt: _date(json['updatedAt']),
        canPack: json['canPack'] == true,
        fulfillmentVersion: _integer(json['fulfillmentVersion']),
      );
}

class PosPickingNoteCommandResult {
  const PosPickingNoteCommandResult({
    required this.orderId,
    required this.fulfillmentOrderId,
    required this.fulfillmentVersion,
    required this.note,
  });
  final String orderId;
  final String fulfillmentOrderId;
  final int fulfillmentVersion;
  final PosPickingNote note;

  factory PosPickingNoteCommandResult.fromJson(Map<String, dynamic> json) =>
      PosPickingNoteCommandResult(
        orderId: _text(json['orderId']),
        fulfillmentOrderId: _text(json['fulfillmentOrderId']),
        fulfillmentVersion: _integer(json['fulfillmentVersion']),
        note: PosPickingNote.fromJson(
          Map<String, dynamic>.from(json['note'] as Map? ?? const {}),
        ),
      );
}

String _text(Object? value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

String? _optionalText(Object? value) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? null : result;
}

int _integer(Object? value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;

double _decimal(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');
