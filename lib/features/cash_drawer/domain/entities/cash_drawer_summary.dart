class CashDrawerSummary {
  const CashDrawerSummary({
    required this.tillName,
    required this.status,
    required this.openedBy,
    required this.openedTime,
    required this.openingCash,
    required this.cashSales,
    required this.cashRefunds,
    required this.cashDrops,
    required this.cashIns,
    required this.cashOuts,
    required this.currentExpectedCash,
  });

  final String tillName;
  final String status;
  final String openedBy;
  final DateTime? openedTime;
  final double openingCash;
  final double cashSales;
  final double cashRefunds;
  final double cashDrops;
  final double cashIns;
  final double cashOuts;
  final double currentExpectedCash;

  bool get isOpen => status.toLowerCase() == 'open';

  CashDrawerSummary copyWith({
    String? tillName,
    String? status,
    String? openedBy,
    DateTime? openedTime,
    double? openingCash,
    double? cashSales,
    double? cashRefunds,
    double? cashDrops,
    double? cashIns,
    double? cashOuts,
    double? currentExpectedCash,
  }) {
    return CashDrawerSummary(
      tillName: tillName ?? this.tillName,
      status: status ?? this.status,
      openedBy: openedBy ?? this.openedBy,
      openedTime: openedTime ?? this.openedTime,
      openingCash: openingCash ?? this.openingCash,
      cashSales: cashSales ?? this.cashSales,
      cashRefunds: cashRefunds ?? this.cashRefunds,
      cashDrops: cashDrops ?? this.cashDrops,
      cashIns: cashIns ?? this.cashIns,
      cashOuts: cashOuts ?? this.cashOuts,
      currentExpectedCash: currentExpectedCash ?? this.currentExpectedCash,
    );
  }
}
