import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/data/models/create_outlet_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/data/models/outlet_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_details.dart';

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
    test('maps form fields to backend create payload', () {
      const dto = CreateOutletRequestDto(
        outletName: 'New Outlet',
        outletCode: '',
        outletType: 'Retail',
        status: 'Active',
        mainPhoneNumber: '+94771234567',
        emailAddress: 'outlet@test.com',
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: 'LK',
        postalCode: '00100',
        openingHours: [
          OutletOpeningHour(
            day: 'Mon',
            openTime: '09:00',
            closeTime: '18:00',
            closed: false,
          ),
        ],
      );

      final json = dto.toJson();

      expect(json['name'], 'New Outlet');
      expect(json['status'], 'ACTIVE');
      expect(json['outletType'], 'STORE');
      expect(json['contactPhone'], '+94771234567');
      expect(json['contactEmail'], 'outlet@test.com');
      expect(json['isOnlineVisible'], isTrue);
      expect(json['collectionEnabled'], isFalse);
      expect(json['address'], isA<Map>());
      expect(json['address']['addressLine1'], 'Line 1');
      expect(json['address']['city'], 'Colombo');
      expect(json['address']['countryCode'], 'LK');
      expect(json['businessHours'], [
        {
          'dayOfWeek': 1,
          'openTime': '09:00:00',
          'closeTime': '18:00:00',
        },
      ]);
      expect(json.containsKey('code'), isFalse);
    });
  });
}
