/// Step 5 barcode type inference and format checks.
/// Mirrors backend [ProductBarcodeFormatValidator] for UX; server remains authoritative.
/// SIMPLE/BUNDLE hide the type dropdown — type is still persisted internally.
library;

const String kBarcodeTypeEan13 = 'EAN13';
const String kBarcodeTypeEan8 = 'EAN8';
const String kBarcodeTypeUpcA = 'UPCA';
const String kBarcodeTypeCode128 = 'CODE128';
const String kBarcodeTypeCode39 = 'CODE39';

const _allowedTypes = {
  kBarcodeTypeEan13,
  kBarcodeTypeEan8,
  kBarcodeTypeUpcA,
  kBarcodeTypeCode128,
  kBarcodeTypeCode39,
};

final _code39 = RegExp(r'^[0-9A-Z\-.\s$/+%]*$');
final _code128 = RegExp(r'^[\x20-\x7E]*$');

String? normalizeBarcodeType(String? barcodeType) {
  if (barcodeType == null || barcodeType.trim().isEmpty) return null;
  final normalized =
      barcodeType.trim().replaceAll('-', '').toUpperCase();
  return _allowedTypes.contains(normalized) ? normalized : null;
}

/// When barcode is empty, type is not required.
/// Prefer a still-valid existing type; otherwise infer (never hard-code EAN13).
String? resolveBarcodeType({
  required String? barcode,
  String? existingType,
}) {
  final value = barcode?.trim() ?? '';
  if (value.isEmpty) return null;

  final existing = normalizeBarcodeType(existingType);
  if (existing != null && validateBarcodeFormat(value, existing) == null) {
    return existing;
  }
  return inferBarcodeType(value);
}

/// Infer type from the value. 13/12/8 digit GTINs with valid checksum map to
/// EAN13/UPCA/EAN8. Everything else is CODE128 (hidden-UI internal default).
String? inferBarcodeType(String? barcode) {
  final value = barcode?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.length > 100) return kBarcodeTypeCode128;

  final allDigits = value.isNotEmpty && value.split('').every(_isDigit);
  if (allDigits) {
    if (value.length == 13 && _passesGtinChecksum(value)) {
      return kBarcodeTypeEan13;
    }
    if (value.length == 12 && _passesGtinChecksum(value)) {
      return kBarcodeTypeUpcA;
    }
    if (value.length == 8 && _passesGtinChecksum(value)) {
      return kBarcodeTypeEan8;
    }
  }
  return kBarcodeTypeCode128;
}

/// Returns an error message, or null when valid / barcode blank.
String? validateBarcodeFormat(String? barcode, String? barcodeType) {
  final value = barcode?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.length > 100) {
    return 'Barcode cannot exceed 100 characters.';
  }

  final type = normalizeBarcodeType(barcodeType);
  if (type == null) {
    return 'Barcode type is required when a barcode is provided.';
  }

  switch (type) {
    case kBarcodeTypeEan13:
      return _validateEan(value, 13);
    case kBarcodeTypeEan8:
      return _validateEan(value, 8);
    case kBarcodeTypeUpcA:
      return _validateEan(value, 12);
    case kBarcodeTypeCode128:
      return _code128.hasMatch(value)
          ? null
          : 'CODE128 barcode contains invalid characters.';
    case kBarcodeTypeCode39:
      return _code39.hasMatch(value)
          ? null
          : 'CODE39 barcode contains invalid characters.';
    default:
      return 'Unsupported barcode type.';
  }
}

String? _validateEan(String value, int expectedLength) {
  if (value.length != expectedLength) {
    return 'Barcode must be exactly $expectedLength digits for the selected type.';
  }
  if (!value.split('').every(_isDigit)) {
    return 'Barcode must contain only digits for the selected type.';
  }
  if (!_passesGtinChecksum(value)) {
    return 'Barcode checksum is invalid.';
  }
  return null;
}

bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

bool _passesGtinChecksum(String digits) {
  var sum = 0;
  var multiplyByThree = true;
  for (var i = digits.length - 2; i >= 0; i--) {
    final n = digits.codeUnitAt(i) - 48;
    sum += multiplyByThree ? n * 3 : n;
    multiplyByThree = !multiplyByThree;
  }
  final check = (10 - (sum % 10)) % 10;
  return check == digits.codeUnitAt(digits.length - 1) - 48;
}
