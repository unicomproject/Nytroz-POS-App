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
  ]) : super('UNSUPPORTED_PLATFORM', message);
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
      : super('CONNECTION_FAILED', message);
}

class PrinterSendException extends PrinterException {
  const PrinterSendException(String message) : super('WRITE_FAILED', message);
}

class PrinterPermissionDeniedException extends PrinterException {
  const PrinterPermissionDeniedException([
    String message = 'Printer permission was denied.',
  ]) : super('PERMISSION_DENIED', message);
}

class PrinterDeviceNotFoundException extends PrinterException {
  const PrinterDeviceNotFoundException([
    String message = 'Configured printer device was not found.',
  ]) : super('DEVICE_NOT_FOUND', message);
}

class PrinterTimeoutException extends PrinterException {
  const PrinterTimeoutException([
    String message = 'Printer operation timed out.',
  ]) : super('TIMEOUT', message);
}

class PrinterPartialWriteException extends PrinterException {
  const PrinterPartialWriteException([
    String message = 'Printer write completed only partially.',
  ]) : super('PARTIAL_WRITE', message);
}

class PrinterNotConnectedException extends PrinterException {
  const PrinterNotConnectedException([
    String message = 'Printer is not connected.',
  ]) : super('NOT_CONNECTED', message);
}
