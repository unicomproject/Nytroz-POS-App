import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/device_configuration/models/pos_hardware_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/presentation/widgets/hardware_test_session_card.dart';

void main() {
  final config = PosHardwareConfiguration.fromJson({
    'configurationId': 'c',
    'hardwareType': 'receiptPrinter',
    'configurationVersion': 2,
  });
  HardwareTestOperation result(
          {bool? confirmed = true,
          String type = 'testPrint',
          int version = 2}) =>
      HardwareTestOperation.fromJson({
        'testId': 'test',
        'hardwareType': 'receiptPrinter',
        'testType': type,
        'status': 'Passed',
        'configurationVersion': version,
        'physicalConfirmation': confirmed,
        'completedAt': '2026-09-13T00:00:00Z',
      });
  test('only a new matching physical test counts', () {
    expect(sessionTestStatus(config, [result()], {}), 'Passed');
    expect(sessionTestStatus(config, [result()], {'test'}), 'Not tested');
    expect(sessionTestStatus(config, [result(confirmed: null)], {}),
        'Confirmation required');
    expect(sessionTestStatus(config, [result(version: 1)], {}), 'Not tested');
    expect(sessionTestStatus(config, [result(type: 'agentHealth')], {}),
        'Not tested');
  });
  test('empty session and provider types cannot report passed', () {
    expect(sessionTestStatus(config, [], {}), 'Not tested');
    expect(
        sessionTestStatus(
            PosHardwareConfiguration.fromJson({'hardwareType': 'cardTerminal'}),
            [],
            {}),
        'Unsupported');
  });
}
