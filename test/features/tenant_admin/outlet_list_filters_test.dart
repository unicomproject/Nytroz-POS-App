import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/utils/outlet_list_filters.dart';

void main() {
  group('outlet_list_filters', () {
    const outlets = [
      Outlet(
        id: '1',
        name: 'Active Outlet',
        code: 'A1',
        location: 'London',
        status: 'Active',
        tillCount: 1,
        onlineTillCount: 1,
        staffCount: 2,
        todaysSales: '£10',
      ),
      Outlet(
        id: '2',
        name: 'Inactive Outlet',
        code: 'I1',
        location: 'Leeds',
        status: 'Inactive',
        tillCount: 0,
        onlineTillCount: 0,
        staffCount: 0,
        todaysSales: '£0',
      ),
    ];

    test('filters active outlets', () {
      final filtered = filterOutletsByStatus(
        outlets,
        OutletStatusFilter.active,
      );

      expect(filtered, hasLength(1));
      expect(filtered.first.name, 'Active Outlet');
    });

    test('filters inactive outlets', () {
      final filtered = filterOutletsByStatus(
        outlets,
        OutletStatusFilter.inactive,
      );

      expect(filtered, hasLength(1));
      expect(filtered.first.name, 'Inactive Outlet');
    });

    test('defaults empty status to active label', () {
      expect(displayOutletStatus(''), 'Active');
    });

    test('maps status filter to API values', () {
      expect(OutletStatusFilter.all.apiStatus, isNull);
      expect(OutletStatusFilter.active.apiStatus, 'active');
      expect(OutletStatusFilter.inactive.apiStatus, 'inactive');
    });
  });
}
