import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/device_configuration/models/pos_hardware_models.dart';

void main() {
  test('maps authoritative device configuration and version', () {
    final model = PosHardwareConfiguration.fromJson({
      'configurationId': 'config-1',
      'posDeviceId': 'device-1',
      'outletId': 'outlet-1',
      'tillId': 'till-1',
      'hardwareType': 'receiptPrinter',
      'transportType': 'localPrintAgent',
      'displayName': 'POSPrinter POS80',
      'enabled': true,
      'configurationVersion': 4,
      'activeShift': true,
      'tillSessionId': 'session-1',
      'settings': {
        'agentBaseUrl': 'http://192.168.18.8:9101',
        'localApiKeyPresent': true,
      },
    });

    expect(model.configurationVersion, 4);
    expect(model.activeShift, isTrue);
    expect(model.settings.containsKey('localApiKey'), isFalse);
    expect(model.settings['localApiKeyPresent'], isTrue);
  });

  test('maps physical and automated hardware-test evidence separately', () {
    final model = HardwareTestOperation.fromJson({
      'testId': 'test-1',
      'requestId': 'request-1',
      'status': 'Passed',
      'resultCategory': 'test_print_submitted',
      'safeMessage': 'Operator confirmed physical output.',
      'physicalConfirmation': true,
      'initiatedAt': '2026-07-29T09:00:00Z',
      'completedAt': '2026-07-29T09:01:00Z',
    });

    expect(model.status, 'Passed');
    expect(model.physicalConfirmation, isTrue);
    expect(model.resultCategory, 'test_print_submitted');
  });
}
