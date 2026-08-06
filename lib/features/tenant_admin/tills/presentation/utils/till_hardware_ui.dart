import 'package:flutter/material.dart';

import '../../domain/entities/till_hardware_readiness.dart';

/// Centralized hardware-type → UI label / icon mapping.
class TillHardwareTypeUi {
  const TillHardwareTypeUi._();

  static String labelFor(String rawType) {
    switch (rawType.trim().toUpperCase()) {
      case 'RECEIPT_PRINTER':
      case 'PRINTER':
        return 'Receipt Printer';
      case 'BARCODE_SCANNER':
      case 'SCANNER':
        return 'Scanner';
      case 'CASH_DRAWER':
        return 'Cash Drawer';
      case 'CARD_READER':
      case 'PAYMENT_TERMINAL':
        return 'Card Reader';
      case 'CUSTOMER_DISPLAY':
        return 'Customer Display';
      case 'SCALE':
        return 'Scale';
      case 'BUILT_IN_CAMERA_SCANNER':
        return 'Camera Scanner';
      default:
        final trimmed = rawType.trim();
        if (trimmed.isEmpty) return 'Hardware';
        return trimmed
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  static IconData iconFor(String rawType) {
    switch (rawType.trim().toUpperCase()) {
      case 'RECEIPT_PRINTER':
      case 'PRINTER':
        return Icons.print;
      case 'BARCODE_SCANNER':
      case 'SCANNER':
        return Icons.document_scanner;
      case 'CASH_DRAWER':
        return Icons.point_of_sale;
      case 'CARD_READER':
      case 'PAYMENT_TERMINAL':
        return Icons.credit_card;
      case 'CUSTOMER_DISPLAY':
        return Icons.desktop_windows_outlined;
      case 'SCALE':
        return Icons.scale;
      case 'BUILT_IN_CAMERA_SCANNER':
        return Icons.photo_camera_outlined;
      default:
        return Icons.device_hub;
    }
  }
}

/// Centralized connection-status → UI presentation mapping.
class TillHardwareConnectionStatusUi {
  const TillHardwareConnectionStatusUi._(this.status);

  factory TillHardwareConnectionStatusUi.of(
    TillHardwareConnectionStatus status,
  ) {
    return TillHardwareConnectionStatusUi._(status);
  }

  final TillHardwareConnectionStatus status;

  String get label {
    switch (status) {
      case TillHardwareConnectionStatus.connected:
        return 'Connected';
      case TillHardwareConnectionStatus.disconnected:
        return 'Disconnected';
      case TillHardwareConnectionStatus.needsAttention:
        return 'Needs Attention';
      case TillHardwareConnectionStatus.maintenance:
        return 'Maintenance';
      case TillHardwareConnectionStatus.notAssigned:
        return 'Not assigned';
      case TillHardwareConnectionStatus.unknown:
        return 'Unknown';
    }
  }

  Color get color {
    switch (status) {
      case TillHardwareConnectionStatus.connected:
        return Colors.green;
      case TillHardwareConnectionStatus.disconnected:
        return Colors.red;
      case TillHardwareConnectionStatus.needsAttention:
        return Colors.orange;
      case TillHardwareConnectionStatus.maintenance:
        return Colors.amber.shade800;
      case TillHardwareConnectionStatus.notAssigned:
      case TillHardwareConnectionStatus.unknown:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (status) {
      case TillHardwareConnectionStatus.connected:
        return Icons.check_circle;
      case TillHardwareConnectionStatus.disconnected:
        return Icons.cancel;
      case TillHardwareConnectionStatus.needsAttention:
        return Icons.warning_amber_rounded;
      case TillHardwareConnectionStatus.maintenance:
        return Icons.build_circle_outlined;
      case TillHardwareConnectionStatus.notAssigned:
        return Icons.link_off;
      case TillHardwareConnectionStatus.unknown:
        return Icons.help_outline;
    }
  }
}
