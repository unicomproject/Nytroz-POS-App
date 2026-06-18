import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/data/models/tenant_dashboard_summary_dto.dart';

void main() {
  group('TenantDashboardSummaryDto', () {
    test('parses wrapped ApiResponse payload', () {
      final dto = TenantDashboardSummaryDto.fromJson({
        'success': true,
        'message': 'Tenant admin dashboard summary loaded successfully.',
        'data': {
          'todaySales': {
            'amount': 3245.50,
            'currency': 'LKR',
            'growthPercent': 12.5,
          },
          'orders': {
            'count': 128,
            'growthPercent': 8.7,
          },
          'activeOutlets': {
            'count': 5,
            'onlineCount': 4,
          },
          'needsAttention': {
            'offlineTills': 2,
            'lowStockItems': 14,
          },
        },
      });

      expect(dto.todaySales?.amount, 3245.50);
      expect(dto.orders?.count, 128);
      expect(dto.activeOutlets?.onlineCount, 4);
      expect(dto.needsAttention?.offlineTills, 2);
    });

    test('maps summary metrics for dashboard cards', () {
      final dashboard = TenantDashboardSummaryDto.fromJson({
        'data': {
          'todaySales': {
            'amount': 100,
            'currency': 'LKR',
            'growthPercent': 5,
          },
          'orders': {
            'count': 10,
            'growthPercent': 2,
          },
        },
      }).toDashboardDto();

      expect(dashboard.metrics, hasLength(2));
      expect(dashboard.metrics.first.key, 'sales');
      expect(dashboard.metrics.first.value, 'LKR 100.00');
      expect(dashboard.salesThisWeek, isNull);
      expect(dashboard.needsAttention, isEmpty);
    });
  });
}
