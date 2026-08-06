import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';

typedef CashPaymentLogSink = void Function(
  String message, {
  required String event,
});

String cashPaymentCorrelation(String idempotencyKey) =>
    sha256.convert(utf8.encode(idempotencyKey)).toString().substring(0, 12);

class CashPaymentTrace {
  CashPaymentTrace._();

  static CashPaymentLogSink sink = _defaultSink;

  static void emit(String event, Map<String, Object?> fields) {
    final safeFields = <String, Object?>{'event': event, ...fields};
    sink(jsonEncode(safeFields), event: event);
  }

  static void resetSink() => sink = _defaultSink;

  static void _defaultSink(String message, {required String event}) {
    developer.log(message, name: 'pos.cash_payment');
  }
}

class CashPaymentFailure {
  const CashPaymentFailure({
    required this.message,
    required this.correlation,
    this.code,
    this.unknownOutcome = false,
  });

  final String message;
  final String correlation;
  final String? code;
  final bool unknownOutcome;
}
