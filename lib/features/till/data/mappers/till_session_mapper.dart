import '../../domain/entities/open_till.dart';

ClosedTillSession closedTillSessionFromJson(Map<String, dynamic> json) {
  final session = _map(_unwrapApiData(json)['tillSession']);

  return ClosedTillSession(
    sessionId: _string(session['id']),
    outletId: _string(session['outletId']),
    tillId: _string(session['tillId']),
    openingFloat: _optionalDouble(session['openingFloat']),
    expectedCash: _optionalDouble(session['expectedCash']),
    countedCash: _optionalDouble(session['countedCash']),
    cashDifference: _optionalDouble(session['cashDifference']),
    status: _string(session['status'], fallback: 'closed'),
    openedAt: DateTime.tryParse(_string(session['openedAt'])) ?? DateTime.now(),
    closedAt: DateTime.tryParse(_string(session['closedAt'])) ?? DateTime.now(),
    closingNote: session['closingNote']?.toString(),
  );
}

Map<String, dynamic> _unwrapApiData(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  return json;
}

TillSession tillSessionFromJson(
  Map<String, dynamic> json,
  OpenTillForm form,
) {
  final session = _map(_unwrapApiData(json)['tillSession']);
  final device = form.deviceContext;

  if (_string(session['id']).isEmpty ||
      _string(session['status']).toLowerCase() != 'open' ||
      _string(session['tillId']) != device.tillId ||
      _string(session['outletId']) != device.outletId) {
    throw const TillException('Current till session response is invalid.',
        code: 'till_session.invalid_response');
  }

  return TillSession(
    sessionId: _string(session['id']),
    tenantId: device.tenantId,
    outletId: _string(session['outletId'], fallback: device.outletId),
    outletName: device.outletName,
    tillId: _string(session['tillId'], fallback: device.tillId),
    tillCode: device.tillCode,
    tillName: _string(session['tillName'], fallback: device.tillName),
    openedDeviceId: _string(
      session['openedDeviceId'],
      fallback: device.deviceId,
    ),
    openingFloat: _optionalDouble(session['openingFloat']) ?? form.openingFloat,
    status: _string(session['status']).toLowerCase(),
    openedAt: DateTime.tryParse(_string(session['openedAt'])) ?? DateTime.now(),
    openingNote: session['openingNote']?.toString(),
    currencyCode: _string(
      session['currencyCode'],
      fallback: device.currencyCode,
    ),
    expectedCash: _optionalDouble(session['expectedCash']),
    openedByName: session['openedByName']?.toString(),
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) {
    return fallback;
  }

  return text;
}

double? _optionalDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
