class PrinterException implements Exception {
  const PrinterException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class PrinterNotConfiguredException extends PrinterException {
  const PrinterNotConfiguredException([
    String message = 'No receipt printer is configured for this POS device.',
  ]) : super('printer_not_configured', message);
}

class PrinterUnsupportedException extends PrinterException {
  const PrinterUnsupportedException([
    String message =
        'This printer connection type is not supported on this platform.',
  ]) : super('printer_unsupported', message);
}

class PrinterConfigurationException extends PrinterException {
  const PrinterConfigurationException(String message)
      : super('configuration_invalid', message);
}

class PrinterOutcomeUnknownException extends PrinterException {
  const PrinterOutcomeUnknownException(String message)
      : super('partial_or_unknown_output', message);
}

class PrinterConnectionException extends PrinterException {
  const PrinterConnectionException(String message)
      : super('printer_connection_failed', message);
}

class PrinterSendException extends PrinterException {
  const PrinterSendException(String message)
      : super('printer_send_failed', message);
}
