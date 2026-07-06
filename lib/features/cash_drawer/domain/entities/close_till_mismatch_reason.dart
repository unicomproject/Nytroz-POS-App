/// Mismatch reason options for the close till form.
///
class CloseTillMismatchReason {
  const CloseTillMismatchReason._();

  static const cashHandlingMismatch = 'Cash Handling Mismatch';
  static const countingError = 'Counting Error';
  static const cashMissing = 'Cash Missing';
  static const cashOver = 'Cash Over';
  static const other = 'Other';

  static const List<String> options = [
    cashHandlingMismatch,
    countingError,
    cashMissing,
    cashOver,
    other,
  ];
}
