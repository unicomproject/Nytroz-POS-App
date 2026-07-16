String formatReportValue(Object? value, {String? currencyCode}) {
  if (value == null) {
    return '—';
  }
  if (value is DateTime) {
    return formatReportDateTime(value);
  }
  if (value is num) {
    final number = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return currencyCode == null || currencyCode.trim().isEmpty
        ? number
        : '${currencyCode.trim().toUpperCase()} $number';
  }
  if (value is List) {
    return value.isEmpty ? '—' : value.join(', ');
  }
  final text = value.toString().trim();
  return text.isEmpty ? '—' : text;
}

String formatReportDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatReportDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${formatReportDate(value)} $hour:$minute';
}

String maskReportEmail(String? value) {
  if (value == null || !value.contains('@')) {
    return '—';
  }
  final parts = value.split('@');
  final name = parts.first;
  final visible = name.isEmpty ? '' : name.substring(0, 1);
  return '$visible***@${parts.last}';
}

String maskReportPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '—';
  }
  final text = value.trim();
  if (text.length <= 4) {
    return '*' * text.length;
  }
  return '${'*' * (text.length - 4)}${text.substring(text.length - 4)}';
}
