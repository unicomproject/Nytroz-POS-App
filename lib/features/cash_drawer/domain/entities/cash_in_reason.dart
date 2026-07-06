/// Cash In reason options for the till drawer form.
///
class CashInReason {
  const CashInReason._();

  static const floatAdded = 'Float Added';
  static const pettyCashAdded = 'Petty Cash Added';
  static const cashCorrection = 'Cash Correction';
  static const other = 'Other';

  static const List<String> options = [
    floatAdded,
    pettyCashAdded,
    cashCorrection,
    other,
  ];
}
