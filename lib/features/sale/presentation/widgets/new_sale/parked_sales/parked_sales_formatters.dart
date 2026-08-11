String safeError(Object error) {
  final value = error.toString().trim();
  return value.isEmpty
      ? 'Parked Sale operation failed. Please try again.'
      : value;
}

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

String formatDateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
}

String formatTimeOnly(DateTime value) {
  final local = value.toLocal();
  return '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

String formatMoney(String currency, int value) =>
    '$currency ${formatNumber(value)}.00';

String formatNumber(int value) {
  final raw = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    b.write(raw[i]);
    final remaining = raw.length - i;
    if (remaining > 1 && remaining % 3 == 1) b.write(',');
  }
  return b.toString();
}

String twoDigits(int value) => value.toString().padLeft(2, '0');
