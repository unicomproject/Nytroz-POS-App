import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/models/till_dto.dart';

void main() {
  group('TillListResultDto', () {
    test('parses wrapped API response with summary and items', () {
      final dto = TillListResultDto.fromJson({
        'summary': {
          'totalTills': 28,
          'onlineCount': 18,
          'offlineCount': 6,
          'needsAttentionCount': 4,
        },
        'items': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'outletId': '22222222-2222-2222-2222-222222222222',
            'outletName': 'High Street Store',
            'name': 'Front Counter Till',
            'code': 'TILL-001',
            'status': 'active',
            'operationalStatus': 'online',
            'todaySalesAmount': 1245.60,
            'currency': 'LKR',
            'lastSyncAt': '2026-06-22T10:00:00Z',
          },
        ],
        'page': 1,
        'pageSize': 10,
        'totalCount': 1,
      });

      expect(dto.summary.totalTills, 28);
      expect(dto.items.single.name, 'Front Counter Till');
      expect(dto.items.single.todaySalesAmount, 1245.60);
      expect(dto.items.single.currency, 'LKR');
    });
  });
}
