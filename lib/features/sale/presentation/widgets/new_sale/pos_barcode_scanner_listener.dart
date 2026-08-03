import 'dart:async';

import 'package:flutter/material.dart';

import '../../../application/services/pos_hid_scanner_input_service.dart';

class PosBarcodeScannerListener extends StatefulWidget {
  const PosBarcodeScannerListener({
    required this.child,
    required this.onBarcodeScanned,
    this.enabled = true,
    this.minimumBarcodeLength = 4,
    this.maximumBarcodeLength = 128,
    this.maximumInterKeyDelay = const Duration(milliseconds: 120),
    this.barcodeValidator,
    this.onRejectedBarcode,
    this.onScanRejected,
    super.key,
  })  : assert(minimumBarcodeLength > 0),
        assert(maximumInterKeyDelay > Duration.zero);

  final Widget child;
  final FutureOr<void> Function(String barcode) onBarcodeScanned;
  final bool enabled;
  final int minimumBarcodeLength;
  final int maximumBarcodeLength;
  final Duration maximumInterKeyDelay;
  final bool Function(String barcode)? barcodeValidator;
  final ValueChanged<String>? onRejectedBarcode;
  final void Function(PosHidScanRejection reason, String value)? onScanRejected;

  @override
  State<PosBarcodeScannerListener> createState() =>
      _PosBarcodeScannerListenerState();
}

class _PosBarcodeScannerListenerState extends State<PosBarcodeScannerListener> {
  late PosHidScannerInputService _scanner;

  @override
  void initState() {
    super.initState();
    _createScanner();
  }

  @override
  void didUpdateWidget(covariant PosBarcodeScannerListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _scanner.detach();
    } else if (!oldWidget.enabled && widget.enabled) {
      _scanner.attach();
    } else if (oldWidget.minimumBarcodeLength != widget.minimumBarcodeLength ||
        oldWidget.maximumBarcodeLength != widget.maximumBarcodeLength ||
        oldWidget.maximumInterKeyDelay != widget.maximumInterKeyDelay) {
      _scanner.dispose();
      _createScanner();
    }
  }

  void _createScanner() {
    _scanner = PosHidScannerInputService(
      configuration: PosHidScannerConfiguration(
        minimumBarcodeLength: widget.minimumBarcodeLength,
        maximumBarcodeLength: widget.maximumBarcodeLength,
        interCharacterTimeout: widget.maximumInterKeyDelay,
      ),
      onScan: (barcode) {
        final valid = widget.barcodeValidator?.call(barcode) ?? true;
        if (!valid) {
          widget.onRejectedBarcode?.call(barcode);
          return;
        }
        widget.onBarcodeScanned(barcode);
      },
      onRejected: (reason, value) {
        widget.onRejectedBarcode?.call(value);
        widget.onScanRejected?.call(reason, value);
      },
    );
    if (widget.enabled) _scanner.attach();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
