abstract final class ReceiptPrintIdentity {
  static String forCopy({
    required String operationId,
    required String receiptPurpose,
    required String copyType,
    required int copyIndex,
  }) {
    final source = [
      operationId.trim().toLowerCase(),
      receiptPurpose.trim().toLowerCase(),
      copyType.trim().toUpperCase(),
      copyIndex,
    ].join('|');
    var first = 0xcbf29ce484222325;
    var second = 0x84222325cbf29ce4;
    for (final unit in source.codeUnits) {
      first = ((first ^ unit) * 0x100000001b3) & 0x7fffffffffffffff;
      second = ((second ^ (unit + 31)) * 0x100000001b3) & 0x7fffffffffffffff;
    }
    final hex =
        '${first.toRadixString(16).padLeft(16, '0')}${second.toRadixString(16).padLeft(16, '0')}';
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '4${hex.substring(13, 16)}-a${hex.substring(17, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
