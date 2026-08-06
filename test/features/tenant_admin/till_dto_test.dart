import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/mappers/till_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/models/till_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_hardware_readiness.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_monitoring.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/utils/till_hardware_ui.dart';

void main() {
  group('TillListResultDto', () {
    test('parses tenant-admin API response with summary and items', () {
      final dto = TillListResultDto.fromJson({
        'items': [
          {
            'tillId': '11111111-1111-1111-1111-111111111111',
            'outletId': '22222222-2222-2222-2222-222222222222',
            'outletName': 'High Street Store',
            'tillName': 'Front Counter Till',
            'tillCode': 'TILL-001',
            'status': 'Active',
            'deviceStatus': 'Online',
            'lastActiveAt': '2026-06-22T10:00:00Z',
            'needsAttention': false,
          },
        ],
        'page': 1,
        'pageSize': 10,
        'totalCount': 1,
      },
          summary: const TillListSummaryDto(
            totalTills: 28,
            onlineCount: 18,
            offlineCount: 6,
            inactiveCount: 2,
            needsAttentionCount: 4,
          ));

      expect(dto.summary.totalTills, 28);
      expect(dto.summary.inactiveCount, 2);
      expect(dto.items.single.name, 'Front Counter Till');
      expect(dto.items.single.code, 'TILL-001');
      expect(dto.items.single.operationalStatus, 'online');
      expect(dto.items.single.lastActiveAt, isNotNull);
    });
  });

  group('TillHardwareReadinessDto', () {
    test('parses full readiness contract including alerts and POS device', () {
      final dto = TillHardwareReadinessDto.fromJson({
        'tillId': 'till-1',
        'tillName': 'Front Counter Till',
        'tillCode': 'TILL-001',
        'outletId': 'outlet-1',
        'outletName': 'High Street Store',
        'tillStatus': 'Active',
        'operationalStatus': 'Online',
        'cashier': {
          'tenantUserId': 'user-1',
          'displayName': 'Test Cashier',
        },
        'lastActivityAt': '2026-08-01T10:00:00Z',
        'posDevice': {
          'posDeviceId': 'pos-1',
          'deviceCode': 'POS-1',
          'deviceName': 'Counter Tablet',
          'deviceStatus': 'ACTIVE',
          'isTrusted': true,
          'lastSeenAt': '2026-08-01T10:05:00Z',
        },
        'connections': [
          {
            'hardwareDeviceId': 'hw-1',
            'hardwareDeviceName': 'Counter Scanner',
            'hardwareDeviceType': 'BARCODE_SCANNER',
            'hardwareDeviceCode': 'SCAN-1',
            'operationalStatus': 'ACTIVE',
            'connectionStatus': 'CONNECTED',
            'manufacturer': 'Acme',
            'model': 'X100',
            'warningMessage': null,
            'isPrimary': true,
            'assignmentSource': 'Till',
          },
          {
            'hardwareDeviceId': 'hw-2',
            'hardwareDeviceName': 'Counter Printer',
            'hardwareDeviceType': 'RECEIPT_PRINTER',
            'hardwareDeviceCode': 'PRT-1',
            'operationalStatus': 'ACTIVE',
            'connectionStatus': 'NEEDS_ATTENTION',
            'warningMessage': 'Latest hardware test reported a warning.',
          },
        ],
        'attentionReasons': [
          {
            'code': 'HARDWARE_TEST_WARNING',
            'severity': 'WARNING',
            'message': 'Latest hardware test reported a warning.',
            'hardwareDeviceId': 'hw-2',
            'hardwareType': 'RECEIPT_PRINTER',
            'observedAt': '2026-08-01T10:01:00Z',
          },
        ],
        'alertCount': 1,
      });

      final entity = TillMapper.toHardwareReadiness(dto);

      expect(entity.alertCount, 1);
      expect(entity.currentCashier?.displayName, 'Test Cashier');
      expect(entity.assignedPosDevice?.deviceName, 'Counter Tablet');
      expect(entity.hardwareConnections, hasLength(2));
      expect(
        entity.hardwareConnections.first.connectionStatus,
        TillHardwareConnectionStatus.connected,
      );
      expect(
        entity.hardwareConnections.last.connectionStatus,
        TillHardwareConnectionStatus.needsAttention,
      );
      expect(entity.attentionReasons.single.code, 'HARDWARE_TEST_WARNING');
      expect(entity.displayStatus, TillDisplayStatus.needsAttention);
    });

    test('throws FormatException for invalid connection list items', () {
      expect(
        () => TillHardwareReadinessDto.fromJson({
          'tillId': 'till-1',
          'tillName': 'Front Counter Till',
          'tillCode': 'TILL-001',
          'outletId': 'outlet-1',
          'outletName': 'High Street Store',
          'connections': ['bad-item'],
          'alertCount': 0,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('maps null cashier and empty hardware honestly', () {
      final dto = TillHardwareReadinessDto.fromJson({
        'tillId': 'till-1',
        'tillName': 'Front Counter Till',
        'tillCode': 'TILL-001',
        'outletId': 'outlet-1',
        'outletName': 'High Street Store',
        'operationalStatus': 'Offline',
        'cashier': null,
        'posDevice': null,
        'connections': [],
        'attentionReasons': [],
        'alertCount': 0,
      });

      final entity = TillMapper.toHardwareReadiness(dto);
      expect(entity.currentCashier, isNull);
      expect(entity.assignedPosDevice, isNull);
      expect(entity.hardwareConnections, isEmpty);
      expect(entity.alertCount, 0);
      expect(entity.operationalStatus, TillOperationalStatus.offline);
    });
  });

  group('TillHardwareTypeUi', () {
    test('maps known and unknown hardware types safely', () {
      expect(TillHardwareTypeUi.labelFor('BARCODE_SCANNER'), 'Scanner');
      expect(TillHardwareTypeUi.labelFor('RECEIPT_PRINTER'), 'Receipt Printer');
      expect(TillHardwareTypeUi.labelFor('CUSTOM_WIDGET'), 'Custom Widget');
    });
  });
}
