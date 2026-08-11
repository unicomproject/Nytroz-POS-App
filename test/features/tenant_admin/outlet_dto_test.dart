import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/data/models/create_outlet_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/data/models/outlet_create_options_dto.dart';
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
        outletType: 'Store',
        status: 'ACTIVE',
        mainPhoneNumber: '+94771234567',
        emailAddress: 'outlet@test.com',
        contactName: 'Ops Lead',
        contactPhone: '+94770000000',
        isDefaultOutlet: true,
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: 'LK',
        postalCode: '00100',
        timezone: 'Europe/London',
        openingHours: [
          OutletOpeningHour(
            day: 'Monday',
            openTime: '09:00',
            closeTime: '18:00',
            closed: false,
          ),
          OutletOpeningHour(
            day: 'Sunday',
            openTime: '',
            closeTime: '',
            closed: true,
          ),
        ],
      );

      final json = dto.toJson();

      expect(json['outletName'], 'New Outlet');
      expect(json.containsKey('name'), isFalse);
      expect(json['timezone'], 'Europe/London');
      expect(json['status'], 'ACTIVE');
      expect(json['outletType'], 'STORE');
      expect(json['phone'], '+94771234567');
      expect(json['email'], 'outlet@test.com');
      expect(json['isDefaultOutlet'], isTrue);
      expect(json['collectionEnabled'], isFalse);
      expect(json['address'], isA<Map>());
      expect(json['address']['addressLine1'], 'Line 1');
      expect(json['address']['city'], 'Colombo');
      expect(json['address']['countryCode'], 'LK');
      expect(json['address']['contactName'], 'Ops Lead');
      expect(json['address']['contactPhone'], '+94770000000');
      expect(json['address']['contactEmail'], isNull);
      expect(json['businessHours'], [
        {
          'dayOfWeek': 1,
          'openingTime': '09:00:00',
          'closingTime': '18:00:00',
          'isClosed': false,
        },
        {
          'dayOfWeek': 0,
          'isClosed': true,
        },
      ]);
      expect(json.containsKey('outletCode'), isFalse);
      expect(json.containsKey('code'), isFalse);
    });

    test(
        'keeps operational contact email in address and image identity at root',
        () {
      const dto = CreateOutletRequestDto(
        outletName: 'New Outlet',
        outletType: 'STORE',
        status: 'ACTIVE',
        mainPhoneNumber: '',
        emailAddress: 'general@example.com',
        contactEmail: 'operations@example.com',
        imageMediaAssetId: 'media-1',
        isDefaultOutlet: false,
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: 'lk',
        postalCode: '',
        timezone: 'Asia/Colombo',
        openingHours: [],
      );
      final json = dto.toJson();
      expect(json['email'], 'general@example.com');
      expect(json['address']['contactEmail'], 'operations@example.com');
      expect(json['contactEmail'], isNull);
      expect(json['imageMediaAssetId'], 'media-1');
      expect(json['address']['countryCode'], 'LK');
    });

    test('serializes image operation only for update requests', () {
      const base = CreateOutletRequestDto(
        outletName: 'New Outlet',
        outletType: 'STORE',
        status: 'ACTIVE',
        mainPhoneNumber: '',
        emailAddress: '',
        imageMediaAssetId: 'media-1',
        imageOperation: OutletImageOperation.replace,
        isDefaultOutlet: false,
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: 'LK',
        postalCode: '',
        timezone: 'Asia/Colombo',
        openingHours: [],
      );
      expect(base.toUpdateJson()['imageOperation'], 'REPLACE');
      expect(base.toUpdateJson()['imageMediaAssetId'], 'media-1');
      final remove = CreateOutletRequestDto.fromForm(const OutletFormData(
        outletName: 'New Outlet',
        outletType: 'STORE',
        status: 'ACTIVE',
        mainPhoneNumber: '',
        emailAddress: '',
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: 'LK',
        postalCode: '',
        timezone: 'Asia/Colombo',
        openingHours: [],
        imageOperation: OutletImageOperation.remove,
      ));
      expect(remove.toUpdateJson()['imageOperation'], 'REMOVE');
      expect(remove.toUpdateJson().containsKey('imageMediaAssetId'), isFalse);
    });

    test('does not silently replace unsupported country codes', () {
      const dto = CreateOutletRequestDto(
        outletName: 'New Outlet',
        outletType: 'STORE',
        status: 'ACTIVE',
        mainPhoneNumber: '',
        emailAddress: '',
        isDefaultOutlet: false,
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: 'LKA',
        postalCode: '',
        timezone: 'Asia/Colombo',
        openingHours: [],
      );

      final json = dto.toJson();

      expect(json['address']['countryCode'], 'LKA');
    });

    test('trims and uppercases country code before request serialization', () {
      const dto = CreateOutletRequestDto(
        outletName: 'New Outlet',
        outletType: 'STORE',
        status: 'ACTIVE',
        mainPhoneNumber: '',
        emailAddress: '',
        isDefaultOutlet: false,
        addressLine1: 'Line 1',
        city: 'Colombo',
        country: ' lk ',
        postalCode: '',
        timezone: 'Asia/Colombo',
        openingHours: [],
      );

      final json = dto.toJson();

      expect(json['address']['countryCode'], 'LK');
    });
  });

  group('OutletCreateOptionsDto', () {
    test('parses backend create options payload', () {
      final dto = OutletCreateOptionsDto.fromJson({
        'outletTypes': [
          {'value': 'STORE', 'label': 'Store'},
          {'value': 'WAREHOUSE', 'label': 'Warehouse'},
        ],
        'countries': [
          {'code': 'LK', 'name': 'Sri Lanka'},
          {'code': 'IN', 'name': 'India'},
        ],
        'timezones': [
          {'value': 'Europe/London', 'label': 'Europe/London'},
          {'value': 'Asia/Colombo', 'label': 'Asia/Colombo'},
        ],
        'defaults': {
          'countryCode': 'LK',
          'timezone': {
            'value': 'Europe/London',
            'label': 'Europe/London',
          },
          'status': 'ACTIVE',
        },
      });

      final entity = dto.toEntity();

      expect(entity.outletTypes.first.value, 'STORE');
      expect(entity.outletTypes.first.label, 'Store');
      expect(entity.outletTypes.last.value, 'WAREHOUSE');
      expect(entity.outletTypes.last.label, 'Warehouse');
      expect(entity.countries.first.code, 'LK');
      expect(entity.countries.first.name, 'Sri Lanka');
      expect(entity.countries.first.label, 'Sri Lanka (LK)');
      expect(entity.countries.last.code, 'IN');
      expect(entity.countries.last.name, 'India');
      expect(entity.timezones.first.value, 'Europe/London');
      expect(entity.timezones.first.label, 'Europe/London');
      expect(entity.defaults.countryCode, 'LK');
      expect(entity.defaults.timezone, 'Europe/London');
      expect(entity.defaults.status, 'ACTIVE');
    });

    test('never converts outlet type and timezone option objects to strings',
        () {
      final dto = OutletCreateOptionsDto.fromJson({
        'outletTypes': [
          {'value': 'STORE', 'label': 'Store'},
        ],
        'timezones': [
          {'value': 'Europe/London', 'label': 'Europe/London'},
        ],
      });

      final entity = dto.toEntity();

      expect(entity.outletTypes.single.value, 'STORE');
      expect(entity.timezones.single.value, 'Europe/London');
      expect(entity.outletTypes.single.value, isNot(contains('{value:')));
      expect(entity.timezones.single.value, isNot(contains('{value:')));
    });

    test('never converts country objects to object strings', () {
      final dto = OutletCreateOptionsDto.fromJson({
        'countries': [
          {'code': 'LK', 'name': 'Sri Lanka'},
        ],
      });

      final country = dto.toEntity().countries.single;

      expect(country.code, 'LK');
      expect(country.name, 'Sri Lanka');
      expect(country.code, isNot(contains('{code:')));
    });
  });
}
