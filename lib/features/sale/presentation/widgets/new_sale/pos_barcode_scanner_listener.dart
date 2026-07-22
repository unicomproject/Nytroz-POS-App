import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PosBarcodeScannerListener extends StatefulWidget {
  const PosBarcodeScannerListener({
    required this.child,
    required this.onBarcodeScanned,
    this.enabled = true,
    this.minimumBarcodeLength = 4,
    this.maximumInterKeyDelay = const Duration(milliseconds: 120),
    this.barcodeValidator,
    this.onRejectedBarcode,
    super.key,
  })  : assert(minimumBarcodeLength > 0),
        assert(maximumInterKeyDelay > Duration.zero);

  final Widget child;
  final FutureOr<void> Function(String barcode) onBarcodeScanned;
  final bool enabled;
  final int minimumBarcodeLength;
  final Duration maximumInterKeyDelay;
  final bool Function(String barcode)? barcodeValidator;
  final ValueChanged<String>? onRejectedBarcode;

  @override
  State<PosBarcodeScannerListener> createState() =>
      _PosBarcodeScannerListenerState();
}

class _PosBarcodeScannerListenerState extends State<PosBarcodeScannerListener> {
  final StringBuffer _buffer = StringBuffer();
  late final KeyEventCallback _keyboardHandler;
  Timer? _resetTimer;
  DateTime? _lastCharacterAt;

  @override
  void initState() {
    super.initState();
    _keyboardHandler = _handleKeyEvent;
    HardwareKeyboard.instance.addHandler(_keyboardHandler);
  }

  @override
  void didUpdateWidget(covariant PosBarcodeScannerListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _resetBuffer();
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _completeScan();
      return false;
    }

    final character = event.character;
    if (!_isPrintableCharacter(character)) {
      return false;
    }

    final now = DateTime.now();
    final lastCharacterAt = _lastCharacterAt;
    if (lastCharacterAt != null &&
        now.difference(lastCharacterAt) > widget.maximumInterKeyDelay) {
      _resetBuffer();
    }

    _buffer.write(character);
    _lastCharacterAt = now;
    _restartResetTimer();
    return false;
  }

  bool _isPrintableCharacter(String? character) {
    if (character == null || character.isEmpty) {
      return false;
    }
    return character.runes.every((rune) => rune >= 0x20 && rune != 0x7f);
  }

  void _completeScan() {
    if (_buffer.isEmpty) {
      return;
    }

    final barcode = _buffer.toString().trim();
    _resetBuffer();
    if (barcode.isEmpty) {
      return;
    }

    final isValid = barcode.length >= widget.minimumBarcodeLength &&
        (widget.barcodeValidator?.call(barcode) ?? true);
    if (!isValid) {
      widget.onRejectedBarcode?.call(barcode);
      return;
    }

    widget.onBarcodeScanned(barcode);
  }

  void _restartResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer(widget.maximumInterKeyDelay, _resetBuffer);
  }

  void _resetBuffer() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _buffer.clear();
    _lastCharacterAt = null;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboardHandler);
    _resetBuffer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
