import '../../../sale/domain/entities/pos_checkout_summary.dart';

class PosCreateHoldRequestDto {
  const PosCreateHoldRequestDto(
      {required this.deviceId,
      required this.lines,
      required this.idempotencyKey,
      this.saleType = 'NewSale',
      this.customerId,
      this.reason,
      this.discountApplicationId});
  final String deviceId, saleType, idempotencyKey;
  final String? customerId, reason, discountApplicationId;
  final List<PosCheckoutLineRequest> lines;
  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'saleType': saleType,
        if (customerId?.isNotEmpty == true) 'customerId': customerId,
        'lines': lines.map((e) => e.toJson()).toList(growable: false),
        if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
        if (discountApplicationId?.isNotEmpty == true)
          'discountApplicationId': discountApplicationId,
        'idempotencyKey': idempotencyKey,
      };
}

class PosHoldLineDto {
  const PosHoldLineDto(
      {required this.lineId,
      required this.name,
      required this.qty,
      required this.unitPrice,
      required this.lineTotal,
      this.variantId,
      this.variantName,
      this.sku,
      this.imageUrl,
      this.lineNote});
  final String lineId, name;
  final String? variantId, variantName, sku, imageUrl, lineNote;
  final int qty, unitPrice, lineTotal;
  factory PosHoldLineDto.fromJson(Map<String, dynamic> j) => PosHoldLineDto(
      lineId: _requiredString(j, 'lineId'),
      variantId: _optionalString(j, 'variantId'),
      name: _requiredString(j, 'name'),
      variantName: _optionalString(j, 'variantName'),
      sku: _optionalString(j, 'sku'),
      imageUrl: _optionalString(j, 'imageUrl') ??
          _optionalString(j, 'imageStorageKey'),
      qty: _requiredInt(j, 'qty'),
      unitPrice: _requiredInt(j, 'unitPrice'),
      lineTotal: _requiredInt(j, 'lineTotal'),
      lineNote: _optionalString(j, 'lineNote'));
}

class PosHoldDto {
  const PosHoldDto(
      {required this.holdId,
      required this.holdNumber,
      required this.saleId,
      required this.saleNumber,
      required this.status,
      required this.itemCount,
      required this.subtotal,
      required this.discount,
      required this.tax,
      required this.total,
      required this.currency,
      required this.heldAt,
      required this.lines,
      this.tillId,
      this.tillSessionId,
      this.customerId,
      this.customerName,
      this.reason,
      this.expiresAt});
  final String holdId, holdNumber, saleId, saleNumber, status, currency;
  final String? tillId, tillSessionId, customerId, customerName, reason;
  final int itemCount, subtotal, discount, tax, total;
  final DateTime heldAt;
  final DateTime? expiresAt;
  final List<PosHoldLineDto> lines;
  factory PosHoldDto.fromJson(Map<String, dynamic> j) => PosHoldDto(
      holdId: _requiredString(j, 'holdId'),
      holdNumber: _requiredString(j, 'holdNumber'),
      saleId: _requiredString(j, 'saleId'),
      saleNumber: _requiredString(j, 'saleNumber'),
      tillId: _optionalString(j, 'tillId'),
      tillSessionId: _optionalString(j, 'tillSessionId'),
      customerId: _optionalString(j, 'customerId'),
      customerName: _optionalString(j, 'customerName'),
      reason: _optionalString(j, 'reason'),
      status: _requiredString(j, 'status'),
      itemCount: _requiredInt(j, 'itemCount'),
      subtotal: _requiredInt(j, 'subtotal'),
      discount: _requiredInt(j, 'discount'),
      tax: _requiredInt(j, 'tax'),
      total: _requiredInt(j, 'total'),
      currency: _requiredString(j, 'currency'),
      heldAt: _requiredDate(j, 'heldAt'),
      expiresAt: _optionalDate(j, 'expiresAt'),
      lines: _maps(j['lines'])
          .map(PosHoldLineDto.fromJson)
          .toList(growable: false));
}

class PosHoldListDto {
  const PosHoldListDto(
    this.holds,
    this.totalCount, {
    this.totalValue = 0,
    this.currency = 'LKR',
    this.page = 1,
    this.pageSize = 25,
  });
  final List<PosHoldDto> holds;
  final int totalCount, totalValue, page, pageSize;
  final String currency;
  factory PosHoldListDto.fromJson(Map<String, dynamic> j) => PosHoldListDto(
        _maps(j['holds']).map(PosHoldDto.fromJson).toList(growable: false),
        _requiredInt(j, 'totalCount'),
        totalValue: _requiredInt(j, 'totalValue'),
        currency: _requiredString(j, 'currency'),
        page: _requiredInt(j, 'page'),
        pageSize: _requiredInt(j, 'pageSize'),
      );
}

class PosRecallHoldDto {
  const PosRecallHoldDto(
      {required this.holdId,
      required this.saleId,
      required this.holdNumber,
      required this.deviceId,
      required this.saleType,
      required this.recalledAt,
      required this.lines,
      required this.checkoutSummary,
      this.customerId,
      this.customerName,
      this.reason});
  final String holdId, saleId, holdNumber, deviceId, saleType;
  final String? customerId, customerName, reason;
  final DateTime recalledAt;
  final List<PosCheckoutLineRequest> lines;
  final PosCheckoutSummaryPayload checkoutSummary;
  factory PosRecallHoldDto.fromJson(Map<String, dynamic> j) => PosRecallHoldDto(
      holdId: _requiredString(j, 'holdId'),
      saleId: _requiredString(j, 'saleId'),
      holdNumber: _requiredString(j, 'holdNumber'),
      deviceId: _requiredString(j, 'deviceId'),
      customerId: _optionalString(j, 'customerId'),
      customerName: _optionalString(j, 'customerName'),
      saleType: _requiredString(j, 'saleType'),
      reason: _optionalString(j, 'reason'),
      recalledAt: _requiredDate(j, 'recalledAt'),
      lines: _maps(j['lines'])
          .map((x) => PosCheckoutLineRequest(
              variantId: _requiredString(x, 'variantId'),
              quantity: _requiredInt(x, 'qty'),
              clientLineId: _optionalString(x, 'clientLineId'),
              uomId: _optionalString(x, 'uomId'),
              lineNote: _optionalString(x, 'lineNote'),
              source: _optionalString(x, 'source')))
          .toList(growable: false),
      checkoutSummary: PosCheckoutSummaryPayload.fromJson(
          _requiredMap(j, 'checkoutSummary')));
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> j, String k) {
  final v = j[k] ?? j[_pascal(k)];
  if (v is Map) return Map<String, dynamic>.from(v);
  throw FormatException('Missing or invalid $k');
}

List<Map<String, dynamic>> _maps(Object? v) => v is Iterable
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
String _requiredString(Map<String, dynamic> j, String k) {
  final v = (j[k] ?? j[_pascal(k)])?.toString().trim() ?? '';
  if (v.isEmpty) throw FormatException('Missing $k');
  return v;
}

String? _optionalString(Map<String, dynamic> j, String k) {
  final v = (j[k] ?? j[_pascal(k)])?.toString().trim();
  return v == null || v.isEmpty ? null : v;
}

int _requiredInt(Map<String, dynamic> j, String k) {
  final v = j[k] ?? j[_pascal(k)];
  if (v is num) return v.round();
  final n = int.tryParse(v?.toString() ?? '');
  if (n == null) throw FormatException('Missing or invalid $k');
  return n;
}

DateTime _requiredDate(Map<String, dynamic> j, String k) {
  final v = DateTime.tryParse((j[k] ?? j[_pascal(k)])?.toString() ?? '');
  if (v == null) throw FormatException('Missing or invalid $k');
  return v;
}

DateTime? _optionalDate(Map<String, dynamic> j, String k) {
  final raw = j[k] ?? j[_pascal(k)];
  return raw == null ? null : DateTime.tryParse(raw.toString());
}

String _pascal(String s) => '${s[0].toUpperCase()}${s.substring(1)}';
