String pickingQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

({String label, String shortLabel, bool isOverdue}) pickingUrgency(
  DateTime? collection,
  DateTime? server,
) {
  if (collection == null || server == null) {
    return (label: '', shortLabel: 'Not set', isOverdue: false);
  }
  final difference = collection.difference(server);
  final overdue = difference.isNegative;
  final duration = difference.abs();
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final short = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  return (
    label: overdue ? '(overdue by $short)' : '(in $short)',
    shortLabel: short,
    isOverdue: overdue,
  );
}
