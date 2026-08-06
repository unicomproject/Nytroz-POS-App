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
    return generate(source);
  }

  static String generate(String source) {
    const prime = 16777619;
    final bases = [
      2166136261,
      3582496829,
      1128362489,
      4019283741,
    ];

    final hashes = List<int>.from(bases);

    for (final unit in source.codeUnits) {
      for (var i = 0; i < 4; i++) {
        hashes[i] = ((hashes[i] ^ (unit + i * 31)) * prime) & 0xffffffff;
      }
    }

    final hex = hashes.map((h) => h.toRadixString(16).padLeft(8, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '4${hex.substring(13, 16)}-a${hex.substring(17, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
