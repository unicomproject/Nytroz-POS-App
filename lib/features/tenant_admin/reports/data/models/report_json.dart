Map<String, dynamic> reportJsonMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> reportJsonList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String? reportNullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int reportInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? reportDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

DateTime? reportDateTime(Object? value) {
  final text = reportNullableString(value);
  return text == null ? null : DateTime.tryParse(text);
}

bool reportBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().toLowerCase();
  if (text == 'true') {
    return true;
  }
  if (text == 'false') {
    return false;
  }
  return fallback;
}
