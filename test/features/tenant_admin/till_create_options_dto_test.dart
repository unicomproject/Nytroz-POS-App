import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/models/till_create_options_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/models/create_till_setup_request_dto.dart';

void main() {
  group('Till DTO Tests', () {
    test('TillCreateOptionsDto.fromJson parses correctly', () {
      final json = {
        'outlets': [
          {'id': 'out1', 'name': 'Main', 'code': 'M1', 'status': 'ACTIVE'}
        ],
        'cashiers': [
          {
            'id': 'c1',
            'displayName': 'John',
            'outletIds': ['out1']
          }
        ],
        'posDevices': [
          {
            'id': 'p1',
            'code': 'POS1',
            'name': 'Tab1',
            'outletId': 'out1',
            'status': 'ACTIVE',
            'isTrusted': true,
            'isAssigned': false
          }
        ],
        'hardwareDevices': [
          {
            'id': 'h1',
            'code': 'HW1',
            'name': 'Scan1',
            'type': 'barcode_scanner',
            'outletId': 'out1',
            'status': 'ACTIVE',
            'isAssigned': false,
            'connectionStatus': 'ONLINE'
          }
        ],
        'statuses': ['ACTIVE', 'INACTIVE'],
        'currencyCode': 'LKR'
      };

      final dto = TillCreateOptionsDto.fromJson(json);

      expect(dto.outlets.length, 1);
      expect(dto.outlets.first.id, 'out1');
      expect(dto.cashiers.first.displayName, 'John');
      expect(dto.posDevices.first.code, 'POS1');
      expect(dto.posDevices.first.isTrusted, true);
      expect(dto.hardwareDevices.first.connectionStatus, 'ONLINE');
      expect(dto.currencyCode, 'LKR');
    });

    test('CreateTillSetupRequestDto generates correct JSON', () {
      const dto = CreateTillSetupRequestDto(
        tillName: ' Till 1 ',
        tillCode: ' t1 ',
        outletId: 'out1',
        status: ' active ',
        defaultCashierTenantUserId: 'c1',
        defaultOpeningFloatAmount: '500.50',
        posDeviceId: ' p1 ',
        hardwareAssignments: [
          CreateTillHardwareAssignmentDto(
              hardwareDeviceId: 'h1', isPrimary: true)
        ],
      );

      final json = dto.toJson();
      expect(json['tillName'], 'Till 1');
      expect(json['tillCode'], 'T1');
      expect(json['status'], 'ACTIVE');
      expect(json['defaultOpeningFloatAmount'], 500.50);
      expect(json['posDeviceId'], 'p1');
      expect((json['hardwareAssignments'] as List).length, 1);
    });
  });
}
