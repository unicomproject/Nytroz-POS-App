enum CashMovementType {
  cashSale,
  cashRefund,
  cashDrop,
  cashIn,
  cashOut,
}

extension CashMovementTypeX on CashMovementType {
  String get label {
    return switch (this) {
      CashMovementType.cashSale => 'Cash Sale',
      CashMovementType.cashRefund => 'Cash Refund',
      CashMovementType.cashDrop => 'Cash Drop',
      CashMovementType.cashIn => 'Cash In',
      CashMovementType.cashOut => 'Cash Out',
    };
  }

  bool get isInflow {
    return this == CashMovementType.cashSale || this == CashMovementType.cashIn;
  }
}

class CashMovement {
  const CashMovement({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    required this.userName,
    this.direction = '',
    this.currencyCode = '',
    this.reason,
    this.note,
  });

  final String id;
  final CashMovementType type;
  final double? amount;
  final DateTime dateTime;
  final String userName;
  final String direction;
  final String currencyCode;
  final String? reason;
  final String? note;
}
