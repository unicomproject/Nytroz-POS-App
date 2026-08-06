import 'dart:async';

import 'package:flutter/services.dart';

enum PosScannerSuffix { enter, newline }

class PosHidScannerConfiguration {
  const PosHidScannerConfiguration({
    this.inputSuffix = PosScannerSuffix.enter,
    this.interCharacterTimeout = const Duration(milliseconds: 120),
    this.minimumBarcodeLength = 4,
    this.maximumBarcodeLength = 128,
  })  : assert(interCharacterTimeout > Duration.zero),
        assert(minimumBarcodeLength > 0),
        assert(maximumBarcodeLength >= minimumBarcodeLength);

  final PosScannerSuffix inputSuffix;
  final Duration interCharacterTimeout;
  final int minimumBarcodeLength;
  final int maximumBarcodeLength;
}

enum PosHidScanRejection { incomplete, invalidLength, unsupportedCharacters }

class PosHidScannerInputService {
  PosHidScannerInputService({
    required this.configuration,
    required this.onScan,
    this.onRejected,
  });

  final PosHidScannerConfiguration configuration;
  final FutureOr<void> Function(String barcode) onScan;
  final void Function(PosHidScanRejection reason, String bufferedValue)?
      onRejected;

  final StringBuffer _buffer = StringBuffer();
  Timer? _timeout;
  DateTime? _lastCharacterAt;
  bool _attached = false;
  bool isConnected = true;

  void simulateDisconnect() {
    isConnected = false;
    reset();
  }

  void simulateReconnect() {
    isConnected = true;
  }

  void attach() {
    if (_attached) return;
    HardwareKeyboard.instance.addHandler(handleKeyEvent);
    _attached = true;
  }

  void detach() {
    if (_attached) {
      HardwareKeyboard.instance.removeHandler(handleKeyEvent);
      _attached = false;
    }
    reset();
  }

  bool handleKeyEvent(KeyEvent event) {
    if (!isConnected) {
      reset();
      return false;
    }
    if (event is! KeyDownEvent) return false;
    if (_isTerminator(event)) {
      _complete();
      return false;
    }

    final character = event.character;
    if (character == null || character.isEmpty) return false;
    if (!_isPrintable(character)) {
      onRejected?.call(
        PosHidScanRejection.unsupportedCharacters,
        _buffer.toString(),
      );
      reset();
      return false;
    }

    final now = DateTime.now();
    if (_lastCharacterAt case final previous?
        when now.difference(previous) > configuration.interCharacterTimeout) {
      if (_buffer.isNotEmpty) {
        onRejected?.call(PosHidScanRejection.incomplete, _buffer.toString());
      }
      reset();
    }

    _buffer.write(character);
    _lastCharacterAt = now;
    if (_buffer.length > configuration.maximumBarcodeLength) {
      onRejected?.call(PosHidScanRejection.invalidLength, _buffer.toString());
      reset();
      return false;
    }
    _restartTimeout();
    return false;
  }

  void reset() {
    _timeout?.cancel();
    _timeout = null;
    _buffer.clear();
    _lastCharacterAt = null;
  }

  void dispose() => detach();

  bool _isTerminator(KeyEvent event) =>
      event.logicalKey == LogicalKeyboardKey.enter ||
      event.logicalKey == LogicalKeyboardKey.numpadEnter;

  bool _isPrintable(String value) =>
      value.runes.every((rune) => rune >= 0x20 && rune != 0x7f);

  void _complete() {
    if (_buffer.isEmpty) return;
    final barcode = _buffer.toString().trim();
    reset();
    if (barcode.length < configuration.minimumBarcodeLength ||
        barcode.length > configuration.maximumBarcodeLength) {
      onRejected?.call(PosHidScanRejection.invalidLength, barcode);
      return;
    }
    onScan(barcode);
  }

  void _restartTimeout() {
    _timeout?.cancel();
    _timeout = Timer(configuration.interCharacterTimeout, () {
      if (_buffer.isNotEmpty) {
        onRejected?.call(PosHidScanRejection.incomplete, _buffer.toString());
      }
      reset();
    });
  }
}
