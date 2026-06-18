import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/data/models/create_outlet_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/data/models/outlet_dto.dart';

void main() {
  group('OutletListResultDto', () {
    test('parses paged API payload', () {
      final dto = OutletListResultDto.fromJson({
        'items': [
          {
            'id': 'outlet-1',
            'name': 'Main Outlet',
            'code': 'OUT-001',
            'status': 'active',
            'tillCount': 2,
            'staffCount': 3,
            'todaySales': {'amount': 1500, 'currency': 'LKR'},
          },
        ],
        'page': 2,
        'pageSize': 10,
        'totalCount': 25,
      });

      expect(dto.page, 2);
      expect(dto.pageSize, 10);
      expect(dto.totalCount, 25);
      expect(dto.items, hasLength(1));
      expect(dto.items.first.name, 'Main Outlet');
      expect(dto.items.first.todaysSales, contains('1500'));
      expect(dto.items.first.todaysSales, contains('LKR'));
    });
  });

  group('CreateOutletRequestDto', () {
    test('maps form fields to backend JSON keys', () {
      const dto = CreateOutletRequestDto(
        outletName: 'New Outlet',
        outletCode: 'OUT-002',
        outletType: 'store',
        mainPhoneNumber: '+94771234567',
        emailAddress: 'outlet@test.com',
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: 'LK',
        postalCode: '00100',
        openingHours: [],
      );

      final json = dto.toJson();

      expect(json['name'], 'New Outlet');
      expect(json['code'], 'OUT-002');
      expect(json['phone'], '+94771234567');
      expect(json['email'], 'outlet@test.com');
      expect(json['status'], 'Active');
    });
  });
}
