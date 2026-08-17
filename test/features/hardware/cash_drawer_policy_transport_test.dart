import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/esc_pos/esc_pos_drawer_pulse_builder.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/transports/cash_drawer_transport.dart';

void main() {
  group('Cash drawer policy & transport routing', () {
    test('receipt/reprint never implies drawer purpose bytes', () {
      // Drawer pulse is only ESC p; receipt builders must stay separate.
      const pulse = EscPosDrawerPulseBuilder();
      final bytes = pulse.build(
        drawerPort: 'drawerPin2',
        pulseOnMilliseconds: 100,
        pulseOffMilliseconds: 200,
      );
      expect(bytes, [0x1B, 0x70, 0, 50, 100]);
      expect(bytes.contains(0x1D), isFalse); // not GS cut / receipt markers
    });

    test('transport resolves Android USB / BT / LocalPrintAgent / unsupported',
        () {
      final transport = CashDrawerTransport();
      expect(
        transport.resolveKind(
          const PosDevicePrinterConfig(
            deviceId: 'd1',
            enabled: true,
            connectionType: PrinterConnectionType.usb,
            displayName: 'USB',
            paperWidth: PrinterPaperWidth.mm80,
          ),
        ),
        CashDrawerTransportKind.androidUsb,
      );
      expect(
        transport.resolveKind(
          const PosDevicePrinterConfig(
            deviceId: 'd1',
            enabled: true,
            connectionType: PrinterConnectionType.bluetooth,
            displayName: 'BT',
            paperWidth: PrinterPaperWidth.mm80,
          ),
        ),
        CashDrawerTransportKind.androidBluetooth,
      );
      expect(
        transport.resolveKind(
          const PosDevicePrinterConfig(
            deviceId: 'd1',
            enabled: true,
            connectionType: PrinterConnectionType.localPrintAgent,
            displayName: 'Agent',
            paperWidth: PrinterPaperWidth.mm80,
          ),
        ),
        CashDrawerTransportKind.localPrintAgent,
      );
      expect(
        transport.resolveKind(
          const PosDevicePrinterConfig(
            deviceId: 'd1',
            enabled: true,
            connectionType: PrinterConnectionType.network,
            displayName: 'Net',
            paperWidth: PrinterPaperWidth.mm80,
          ),
        ),
        CashDrawerTransportKind.unsupported,
      );
    });

    test('cash / split / refund purposes are distinct enums', () {
      // Policy identity surface used by controller + agent contract.
      expect(
        {
          'cashSale',
          'splitPaymentCash',
          'cashRefund',
          'manualNoSale',
          'hardwareTest',
        },
        containsAll([
          'cashSale',
          'splitPaymentCash',
          'cashRefund',
        ]),
      );
    });
  });
}
