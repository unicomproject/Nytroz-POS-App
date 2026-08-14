import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/data/mappers/online_store_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/data/models/online_store_dtos.dart';

void main() {
  test('overview dto parses backend envelope payload fields into domain entity',
      () {
    final dto = OnlineStoreOverviewDto.fromJson({
      'salesChannelId': 'channel-1',
      'storeStatus': 'DRAFT',
      'channelStatus': 'INACTIVE',
      'setupEnabled': true,
      'visibility': 'NOT_LIVE',
      'storeSlug': 'tenant-store',
      'hostedUrl': 'https://tenant-store.oneverz.shop',
      'completedSteps': 3,
      'totalSteps': 9,
      'setupProgressPercent': 33,
      'steps': [
        {
          'stepNumber': 7,
          'code': 'CLICK_COLLECT',
          'label': 'Click & Collect',
          'status': 'PASS',
          'blockingReasons': ['reason'],
        },
      ],
      'readiness': {
        'canPublish': false,
        'blockingReasons': ['Domain not verified'],
        'steps': [
          {
            'stepNumber': 8,
            'code': 'PRODUCTS_POLICIES',
            'label': 'Products & Policies',
            'status': 'BLOCKED',
            'blockingReasons': ['Policy required'],
          },
        ],
      },
    });

    final entity = dto.toEntity();

    expect(entity.salesChannelId, 'channel-1');
    expect(entity.storeSlug, 'tenant-store');
    expect(entity.setupProgressPercent, 33);
    expect(entity.steps.single.stepNumber, 7);
    expect(entity.steps.single.label, 'Click & Collect');
    expect(entity.readiness.canPublish, isFalse);
    expect(entity.readiness.steps.single.stepNumber, 8);
  });

  test('nullable dto strings trim blanks to null', () {
    final dto = OnlineStoreIdentityDto.fromJson({
      'salesChannelId': 'channel-1',
      'storeName': 'Store',
      'businessDisplayName': 'Store Display',
      'storeDescription': '   ',
      'storeEmail': '',
      'storePhone': null,
      'supportTagline': ' Help ',
      'currencyCode': 'LKR',
      'timezone': 'Asia/Colombo',
    });

    expect(dto.storeDescription, isNull);
    expect(dto.storeEmail, isNull);
    expect(dto.storePhone, isNull);
    expect(dto.supportTagline, 'Help');
  });

  test('publish dto maps backend readiness and published timestamp', () {
    final publishedAt = DateTime.utc(2026, 8, 14, 9, 30);
    final dto = OnlineStorePublishDto.fromJson({
      'storeStatus': 'PUBLISHED',
      'channelStatus': 'ACTIVE',
      'publishedAt': publishedAt.toIso8601String(),
      'readiness': {
        'canPublish': true,
        'blockingReasons': <String>[],
        'steps': <Map<String, Object>>[],
      },
    });

    final entity = dto.toEntity();

    expect(entity.storeStatus, 'PUBLISHED');
    expect(entity.channelStatus, 'ACTIVE');
    expect(entity.publishedAt, publishedAt);
    expect(entity.readiness.canPublish, isTrue);
  });
}
