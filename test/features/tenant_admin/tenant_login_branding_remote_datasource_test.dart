import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/domain/entities/pos_login_branding.dart';
import 'package:nytroz_pos/features/tenant_admin/login_branding/data/datasources/tenant_login_branding_remote_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/login_branding/domain/entities/tenant_login_branding_settings.dart';

void main() {
  test('GET maps configured and effective branding', () async {
    final adapter = _BrandingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final result = await TenantLoginBrandingRemoteDatasource(dio).get();

    expect(adapter.lastMethod, 'GET');
    expect(result.systemName, 'Configured system');
    expect(result.effective.tenantSlug, 'tenant-a');
  });

  test('PUT sends canonical COLOR request including nullable media', () async {
    final adapter = _BrandingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    await TenantLoginBrandingRemoteDatasource(dio).update(
      const UpdateTenantLoginBrandingSettings(
        systemName: 'Configured system',
        description: 'Description',
        subtitleTemplate: 'Sign in to {tenantName}',
        backgroundMode: PosLoginBackgroundMode.color,
        backgroundColor: '#FF6A00',
      ),
    );

    expect(adapter.lastMethod, 'PUT');
    expect(adapter.lastData, containsPair('backgroundMode', 'COLOR'));
    expect(adapter.lastData, containsPair('backgroundMediaAssetId', null));
  });

  test('POST uploads purpose-scoped branding media', () async {
    final adapter = _BrandingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final result = await TenantLoginBrandingRemoteDatasource(dio).uploadMedia(
      'POS_LOGIN_HERO',
      TenantLoginBrandingMediaInput(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'hero.webp',
        mimeType: 'image/webp',
      ),
    );

    expect(adapter.lastMethod, 'POST');
    expect(adapter.lastPath, endsWith('/media/POS_LOGIN_HERO'));
    expect(result.mediaAssetId, '00000000-0000-4000-8000-000000000001');
    expect(result.purpose, 'POS_LOGIN_HERO');
  });
}

class _BrandingAdapter implements HttpClientAdapter {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastMethod = options.method;
    lastPath = options.path;
    lastData = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : null;
    if (options.method == 'POST') {
      return ResponseBody.fromString(
        '''{"mediaAssetId":"00000000-0000-4000-8000-000000000001","purpose":"POS_LOGIN_HERO","publicUrl":"https://cdn.example.test/hero.webp"}''',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '''{"configured":{"systemName":"Configured system","description":"Description","subtitleTemplate":"Sign in to {tenantName}","backgroundMode":"COLOR","backgroundColor":"#FF6A00","backgroundMediaAssetId":null,"heroMediaAssetId":null},"effective":{"tenantSlug":"tenant-a","brandDisplayName":"Tenant A","systemName":"Configured system","description":"Description","loginSubtitle":"Sign in to Tenant A","backgroundMode":"COLOR","backgroundColor":"#FF6A00","logoUrl":null,"backgroundImageUrl":null,"heroImageUrl":null,"updatedAt":"2026-08-10T00:00:00Z"}}''',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
