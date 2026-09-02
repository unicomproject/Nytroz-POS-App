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
      'domain': {
        'configured': true,
        'domain': 'store.tenant.lk',
        'dnsStatus': 'VERIFIED',
        'sslStatus': 'ACTIVE',
        'isPrimary': true,
      },
      'branding': {'status': 'CONFIGURED'},
      'contactSupport': {'status': 'COMPLETE'},
      'clickCollect': {
        'enabled': true,
        'eligibleOutletCount': 2,
        'status': 'READY',
      },
      'catalog': {'totalProducts': 186, 'onlineVisibleProducts': 124},
      'policies': {
        'requiredCount': 4,
        'publishedRequiredCount': 3,
        'status': 'INCOMPLETE',
      },
      'customerAccountMode': 'REGISTRATION_REQUIRED',
      'emailVerificationRequired': true,
      'paymentMode': 'PAY_AT_PICKUP',
      'notificationsStatus': 'READY',
      'nextActions': [
        {'code': 'CLICK_COLLECT', 'step': 7, 'blocking': true},
      ],
    });

    final entity = dto.toEntity();

    expect(entity.salesChannelId, 'channel-1');
    expect(entity.storeSlug, 'tenant-store');
    expect(entity.setupProgressPercent, 33);
    expect(entity.steps.single.stepNumber, 7);
    expect(entity.steps.single.label, 'Click & Collect');
    expect(entity.readiness.canPublish, isFalse);
    expect(entity.readiness.steps.single.stepNumber, 8);
    expect(entity.domain.domain, 'store.tenant.lk');
    expect(entity.domain.isPrimary, isTrue);
    expect(entity.branding.status, 'CONFIGURED');
    expect(entity.contactSupport.status, 'COMPLETE');
    expect(entity.clickCollect.eligibleOutletCount, 2);
    expect(entity.catalog.onlineVisibleProducts, 124);
    expect(entity.policies.publishedRequiredCount, 3);
    expect(entity.customerAccountMode, 'REGISTRATION_REQUIRED');
    expect(entity.emailVerificationRequired, isTrue);
    expect(entity.paymentMode, 'PAY_AT_PICKUP');
    expect(entity.notificationsStatus, 'READY');
    expect(entity.nextActions.single.code, 'CLICK_COLLECT');
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

  test('activation dto maps release configuration and backend readiness', () {
    final dto = OnlineStoreActivationDto.fromJson({
      'setupEnabled': true,
      'storeStatus': 'DRAFT',
      'channelStatus': 'INACTIVE',
      'visibility': 'NOT_LIVE',
      'entitlements': <Map<String, Object>>[],
      'releaseScope': 'CLICK_COLLECT_ONLY',
      'checkoutMode': 'REGISTRATION_REQUIRED',
      'emailVerificationRequired': true,
      'paymentMode': 'PAY_AT_PICKUP',
      'notificationsStatus': 'READY',
      'privateUntilPublished': true,
      'readiness': [
        {
          'code': 'channel_entitlement',
          'label': 'Channel Entitlement',
          'status': 'READY',
          'message': 'Your tenant is entitled to Online Store.',
        },
      ],
    });

    final entity = dto.toEntity();

    expect(entity.releaseScope, 'CLICK_COLLECT_ONLY');
    expect(entity.checkoutMode, 'REGISTRATION_REQUIRED');
    expect(entity.emailVerificationRequired, isTrue);
    expect(entity.paymentMode, 'PAY_AT_PICKUP');
    expect(entity.notificationsStatus, 'READY');
    expect(entity.privateUntilPublished, isTrue);
    expect(entity.readiness.single.code, 'channel_entitlement');
    expect(entity.readiness.single.status, 'READY');
  });

  test('checkout rules dto maps every backend-driven release rule', () {
    final dto = OnlineStoreCheckoutRulesDto.fromJson({
      'release': 'R1',
      'customerAccount': {
        'registrationRequired': true,
        'mode': 'REGISTRATION_REQUIRED',
        'label': 'Registration required',
      },
      'guestCheckout': {
        'available': false,
        'mode': 'NOT_AVAILABLE',
        'label': 'Not available',
      },
      'emailVerification': {
        'required': true,
        'mode': 'REQUIRED',
        'label': 'Required',
      },
      'fulfilment': {
        'mode': 'CLICK_COLLECT',
        'label': 'Click & Collect',
        'featureEnabled': true,
        'configured': false,
      },
      'payment': {
        'mode': 'PAY_AT_PICKUP',
        'label': 'Pay at Pickup',
      },
    });

    final entity = dto.toEntity();

    expect(entity.release, 'R1');
    expect(entity.customerAccount.registrationRequired, isTrue);
    expect(entity.customerAccount.label, 'Registration required');
    expect(entity.guestCheckout.available, isFalse);
    expect(entity.guestCheckout.label, 'Not available');
    expect(entity.emailVerification.required, isTrue);
    expect(entity.fulfilment.label, 'Click & Collect');
    expect(entity.fulfilment.featureEnabled, isTrue);
    expect(entity.fulfilment.configured, isFalse);
    expect(entity.payment.label, 'Pay at Pickup');
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

  test('domain token dto preserves one-time verification token', () {
    final entity = OnlineStoreDomainTokenDto.fromJson({
      'domainId': 'domain-1',
      'domainName': 'store.example.com',
      'verificationToken': 'verification-value',
    }).toEntity();

    expect(entity.domainId, 'domain-1');
    expect(entity.domainName, 'store.example.com');
    expect(entity.verificationToken, 'verification-value');
  });

  test('branding dto preserves backend media URLs and colours', () {
    final entity = OnlineStoreBrandingDto.fromJson({
      'logoMediaAssetId': 'logo-1',
      'faviconMediaAssetId': 'favicon-1',
      'logoImageUrl': 'https://cdn.example.com/logo.png',
      'faviconImageUrl': 'https://cdn.example.com/favicon.ico',
      'primaryColor': '#123456',
      'secondaryColor': '#ABCDEF',
      'banners': <Map<String, Object?>>[],
    }).toEntity();

    expect(entity.logoMediaAssetId, 'logo-1');
    expect(entity.faviconMediaAssetId, 'favicon-1');
    expect(entity.logoImageUrl, 'https://cdn.example.com/logo.png');
    expect(entity.faviconImageUrl, 'https://cdn.example.com/favicon.ico');
    expect(entity.primaryColor, '#123456');
    expect(entity.secondaryColor, '#ABCDEF');
  });

  test('support dto maps all backend fields and preserves nullable values', () {
    final entity = OnlineStoreSupportDto.fromJson({
      'email': 'help@example.test',
      'phone': '+94110000000',
      'whatsapp': null,
      'helpUrl': 'https://support.example.test',
      'contactUsEnabled': false,
      'supportHours': 'Mon - Fri: 9:00 AM - 6:00 PM',
      'businessAddress': 'Example support address',
    }).toEntity();

    expect(entity.email, 'help@example.test');
    expect(entity.phone, '+94110000000');
    expect(entity.whatsapp, isNull);
    expect(entity.helpUrl, 'https://support.example.test');
    expect(entity.contactUsEnabled, isFalse);
    expect(entity.supportHours, 'Mon - Fri: 9:00 AM - 6:00 PM');
    expect(entity.businessAddress, 'Example support address');
  });
}
