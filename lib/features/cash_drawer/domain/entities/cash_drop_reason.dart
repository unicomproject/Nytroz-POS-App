/// Cash Drop reason options for the till drawer form.
///
/// TODO(cash-drawer): Load from backend cash_movement_types when API is ready.
class CashDropReason {
  const CashDropReason._();

  static const safeDrop = 'Safe Drop';
  static const bankDeposit = 'Bank Deposit';
  static const cashPickup = 'Cash Pickup';
  static const securityTransfer = 'Security Transfer';
  static const cashCorrection = 'Cash Correction';
  static const other = 'Other';

  static const List<String> options = [
    safeDrop,
    bankDeposit,
    cashPickup,
    securityTransfer,
    cashCorrection,
    other,
  ];
}
