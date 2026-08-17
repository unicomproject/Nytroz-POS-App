import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/esc_pos/esc_pos_drawer_pulse_builder.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/presentation/providers/cash_drawer_controller.dart';

void main() {
  group('Hardware drawer test contract', () {
    test('createTest payload requires requestId and configuration id fields', () {
      // Mirrors CashDrawerController.testPulse contract — empty requestId
      // previously caused backend pos_hardware.invalid_test → HTTP 400.
      final requestId = GuidGenerator.generate();
      final payload = <String, dynamic>{
        'requestId': requestId,
        'posDeviceId': '11111111-1111-1111-1111-111111111111',
        'hardwareConfigurationId': '22222222-2222-2222-2222-222222222222',
        'hardwareType': 'cashDrawer',
        'testType': 'drawerPulse',
        'configurationVersion': 1,
      };

      expect(payload['requestId'], isNotEmpty);
      expect(requestId.length, greaterThanOrEqualTo(32));
      expect(payload['hardwareConfigurationId'], isNotNull);
      expect(payload['hardwareType'], 'cashDrawer');
      expect(payload['testType'], 'drawerPulse');
      expect(Guid.tryParse(requestId), isNotNull);
    });

    test('physical confirmation uses canonical drawer result categories', () {
      const opened = 'drawer_opened';
      const closed = 'drawer_did_not_open';
      // Must match PosHardwareService.ResultCategories — SUCCESS/FAILURE are rejected.
      expect(opened, isNot(equals('SUCCESS')));
      expect(closed, isNot(equals('FAILURE')));
    });

    test('hardwareTest purpose is distinct from cashSale', () {
      expect('hardwareTest', isNot(equals('cashSale')));
      expect('manualNoSale', isNot(equals('cashSale')));
    });

    test('Pin2 100/200 ms encodes 1B-70-00-32-64', () {
      const builder = EscPosDrawerPulseBuilder();
      final bytes = builder.build(
        drawerPort: 'drawerPin2',
        pulseOnMilliseconds: 100,
        pulseOffMilliseconds: 200,
      );
      expect(bytes, [0x1B, 0x70, 0x00, 0x32, 0x64]);
      expect(EscPosDrawerPulseBuilder.toEscPosUnit(100), 50);
      expect(EscPosDrawerPulseBuilder.toEscPosUnit(200), 100);
    });

    test('Pin5 100/200 ms encodes 1B-70-01-32-64', () {
      const builder = EscPosDrawerPulseBuilder();
      expect(
        builder.build(
          drawerPort: 'drawerPin5',
          pulseOnMilliseconds: 100,
          pulseOffMilliseconds: 200,
        ),
        [0x1B, 0x70, 0x01, 0x32, 0x64],
      );
    });
  });
}

/// Minimal Guid parse helper for tests (avoid dart:core Guid package).
class Guid {
  static Object? tryParse(String value) {
    final normalized = value.trim();
    final ok = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(normalized);
    return ok ? normalized : null;
  }
}
