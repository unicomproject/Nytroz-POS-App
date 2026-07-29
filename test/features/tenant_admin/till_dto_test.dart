import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/models/till_dto.dart';

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
}
