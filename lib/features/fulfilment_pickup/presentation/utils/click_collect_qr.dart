/// Parses the customer-facing collection QR payload:
/// `CLICK_COLLECT:{tenantId}:{orderId}:{pickupCode}`.
///
/// Shared by the "scan an order already on screen" flow (only the code is
/// used) and the "blind scan at the counter" flow (order id is used to look
/// up which order this QR belongs to before anything is shown).
class ClickCollectQrPayload {
  const ClickCollectQrPayload({
    required this.tenantId,
    required this.orderId,
    required this.code,
  });

  final String tenantId;
  final String orderId;
  final String code;

  static ClickCollectQrPayload? tryParse(String? scanned) {
    final value = scanned?.trim();
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 4 || parts[0] != 'CLICK_COLLECT') return null;
    final tenantId = parts[1].trim();
    final orderId = parts[2].trim();
    final code = parts[3].trim();
    if (tenantId.isEmpty || orderId.isEmpty || code.isEmpty) return null;
    return ClickCollectQrPayload(tenantId: tenantId, orderId: orderId, code: code);
  }
}
