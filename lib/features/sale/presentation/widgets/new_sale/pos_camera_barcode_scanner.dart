import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

enum PosCameraScanResultType {
  barcode,
  cancelled,
  permissionDenied,
  unavailable,
  failed,
  unsupported
}

class PosCameraScanResult {
  const PosCameraScanResult._(this.type, [this.barcode]);
  const PosCameraScanResult.barcode(String barcode)
      : this._(PosCameraScanResultType.barcode, barcode);
  const PosCameraScanResult.cancelled()
      : this._(PosCameraScanResultType.cancelled);
  const PosCameraScanResult.permissionDenied()
      : this._(PosCameraScanResultType.permissionDenied);
  const PosCameraScanResult.unavailable()
      : this._(PosCameraScanResultType.unavailable);
  const PosCameraScanResult.failed() : this._(PosCameraScanResultType.failed);
  const PosCameraScanResult.unsupported()
      : this._(PosCameraScanResultType.unsupported);
  final PosCameraScanResultType type;
  final String? barcode;
}

class PosCameraDetectionGate {
  bool _locked = false;

  bool get isLocked => _locked;

  String? accept(Iterable<String?> values) {
    if (_locked) return null;
    for (final value in values) {
      final candidate = value?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        _locked = true;
        return candidate;
      }
    }
    return null;
  }

  void lock() => _locked = true;
}

Future<PosCameraScanResult> launchPosCameraScanner(BuildContext context) async {
  final result = await showDialog<PosCameraScanResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PosCameraBarcodeScannerDialog(),
  );
  return result ?? const PosCameraScanResult.cancelled();
}

class PosCameraBarcodeScannerDialog extends StatefulWidget {
  const PosCameraBarcodeScannerDialog({super.key});
  @override
  State<PosCameraBarcodeScannerDialog> createState() =>
      _PosCameraBarcodeScannerDialogState();
}

class _PosCameraBarcodeScannerDialogState
    extends State<PosCameraBarcodeScannerDialog> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  final PosCameraDetectionGate _detectionGate = PosCameraDetectionGate();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.code128,
        BarcodeFormat.code39
      ],
    );
  }

  Future<void> _accept(BarcodeCapture capture) async {
    final value = _detectionGate.accept(
      capture.barcodes.map((barcode) => barcode.rawValue),
    );
    if (value == null) return;
    await _controller.stop();
    if (mounted) Navigator.of(context).pop(PosCameraScanResult.barcode(value));
  }

  void _completeError(MobileScannerException error) {
    if (_detectionGate.isLocked) return;
    _detectionGate.lock();
    final result = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        const PosCameraScanResult.permissionDenied(),
      MobileScannerErrorCode.unsupported =>
        const PosCameraScanResult.unavailable(),
      _ => const PosCameraScanResult.failed(),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  void _cancel() {
    if (_detectionGate.isLocked) return;
    _detectionGate.lock();
    Navigator.of(context).pop(const PosCameraScanResult.cancelled());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_detectionGate.isLocked) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.xl)),
        child: SizedBox(
          width: size.width.clamp(320, 720),
          height: size.height.clamp(420, 620),
          child: Stack(fit: StackFit.expand, children: [
            MobileScanner(
              controller: _controller,
              onDetect: _accept,
              errorBuilder: (_, error) {
                _completeError(error);
                return const ColoredBox(color: Colors.black);
              },
              placeholderBuilder: (_) => const ColoredBox(
                  color: Colors.black,
                  child: Center(child: CircularProgressIndicator())),
            ),
            IgnorePointer(
                child: Center(
                    child: Container(
              width: 300,
              height: 180,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.lg)),
            ))),
            Positioned(
                top: TenantAdminSpacing.md,
                left: TenantAdminSpacing.md,
                right: TenantAdminSpacing.md,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CameraControlButton(
                        tooltip: 'Close scanner',
                        icon: Icons.close_rounded,
                        onPressed: _cancel),
                    ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller,
                        builder: (_, state, __) => _CameraControlButton(
                              tooltip: 'Toggle torch',
                              icon: state.torchState == TorchState.on
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              onPressed:
                                  state.torchState == TorchState.unavailable
                                      ? null
                                      : _controller.toggleTorch,
                            )),
                  ],
                )),
            const Positioned(
                left: TenantAdminSpacing.md,
                right: TenantAdminSpacing.md,
                bottom: TenantAdminSpacing.lg,
                child: Text(
                  'Place the product barcode inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                )),
          ]),
        ),
      ),
    );
  }
}

class _CameraControlButton extends StatelessWidget {
  const _CameraControlButton(
      {required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.58),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black26),
      );
}
