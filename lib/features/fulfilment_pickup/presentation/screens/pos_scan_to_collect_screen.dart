import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../sale/presentation/widgets/new_sale/pos_camera_barcode_scanner.dart'
    show PosCameraScanResultType;
import '../providers/pos_online_orders_provider.dart';
import '../utils/click_collect_qr.dart';
import '../widgets/online_order_ui.dart';

/// Counter-side entry point for the natural pickup flow: the cashier scans
/// the customer's QR cold -- with no order already selected -- and the
/// system resolves which order it belongs to before showing anything, so
/// staff never need to search the Orders list first.
///
/// Once the order is resolved this hands off to the same
/// [PosOnlineOrderPickingScreen] / [ReadyForCollectionScreen] flow used when
/// an order is opened normally, carrying the already-scanned code forward so
/// the cashier isn't asked to scan the same QR twice.
class PosScanToCollectScreen extends ConsumerStatefulWidget {
  const PosScanToCollectScreen({super.key});

  @override
  ConsumerState<PosScanToCollectScreen> createState() =>
      _PosScanToCollectScreenState();
}

class _PosScanToCollectScreenState
    extends ConsumerState<PosScanToCollectScreen> {
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_scan);
  }

  Future<void> _scan() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final launch = ref.read(posPickupScannerLauncherProvider);
      final result = await launch(
        context,
        formats: const [BarcodeFormat.qrCode],
        instructionText: "Scan the customer's pickup QR code",
      );
      if (!mounted) return;

      if (result.type != PosCameraScanResultType.barcode) {
        setState(() {
          _working = false;
          _error = switch (result.type) {
            PosCameraScanResultType.permissionDenied =>
              'Camera access is disabled. Enable it in system settings.',
            PosCameraScanResultType.unavailable =>
              'No camera is available on this device.',
            PosCameraScanResultType.unsupported =>
              'Camera scanning is unavailable on this device.',
            // A cancelled scan (result.failed with no explicit reason) goes
            // straight back to Orders rather than showing an error.
            _ => null,
          };
        });
        if (_error == null && mounted) context.go('/pos/online-orders');
        return;
      }

      final payload = ClickCollectQrPayload.tryParse(result.barcode);
      if (payload == null) {
        setState(() {
          _working = false;
          _error = 'This is not a valid collection QR code.';
        });
        return;
      }

      // The picking-workspace route resolves the order and shows the
      // right stage (including Ready for Collection) on its own -- it
      // already does this for every other entry point, so scan-to-collect
      // just needs to land there with the code in hand.
      if (!mounted) return;
      context.go(
        '/pos/online-orders/${payload.orderId}/picking',
        extra: payload.code,
      );
    } on DioException {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = 'Unable to look up this order. Try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = 'Unable to look up this order. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return OnlineOrderScreenState(
        message: _error!,
        icon: Icons.qr_code_scanner_outlined,
        onRetry: _scan,
      );
    }
    return const OnlineOrderScreenState(
      message: 'Opening the scanner…',
      icon: Icons.qr_code_scanner_outlined,
    );
  }
}
