import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/data/datasources/tenant_user_remote_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/users/data/models/user_write_request_dto.dart';

void main() {
  group('TenantUserRemoteDatasource.createUser', () {
    test('sends canonical create payload and idempotency header', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter();
      dio.httpClientAdapter = adapter;
      final datasource = TenantUserRemoteDatasource(dio);

      await datasource.createUser(
        const UserWriteRequestDto(
          fullName: ' Kavin Perera ',
          email: ' kavin@oneverz.com ',
          phoneNumber: ' 0771234567 ',
          employeeId: ' EMP-100 ',
          roleId: 'role-1',
          outletIds: ['outlet-1'],
          permissionOverrideEnabled: true,
          overriddenPermissionIds: ['perm-1'],
          status: 'INVITED',
          profileMediaAssetId: 'media-1',
        ),
        idempotencyKey: 'idem-1',
      );

      expect(adapter.lastPath, '/api/v1/tenant-admin/users');
      expect(adapter.lastHeaders['Idempotency-Key'], 'idem-1');
      expect(adapter.lastBody['fullName'], 'Kavin Perera');
      expect(adapter.lastBody['email'], 'kavin@oneverz.com');
      expect(adapter.lastBody['phoneNumber'], '0771234567');
      expect(adapter.lastBody['employeeId'], 'EMP-100');
      expect(adapter.lastBody['roleId'], 'role-1');
      expect(adapter.lastBody['outletIds'], ['outlet-1']);
      expect(adapter.lastBody['permissionOverrideEnabled'], isTrue);
      expect(adapter.lastBody['overriddenPermissionIds'], ['perm-1']);
      expect(adapter.lastBody['createStatus'], 'INVITED');
      expect(adapter.lastBody['profileMediaAssetId'], 'media-1');
      expect(adapter.lastBody.containsKey('staffCode'), isFalse);
      expect(adapter.lastBody.containsKey('defaultOutletId'), isFalse);
      expect(adapter.lastBody.containsKey('password'), isFalse);
      expect(adapter.lastBody.containsKey('inviteToken'), isFalse);
    });

    test('omits optional empty fields and legacy invite boolean', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter();
      dio.httpClientAdapter = adapter;
      final datasource = TenantUserRemoteDatasource(dio);

      await datasource.createUser(
        const UserWriteRequestDto(
          fullName: 'Nadeesha Dias',
          email: 'nadeesha@oneverz.com',
          phoneNumber: '',
          employeeId: '',
          roleId: 'role-1',
          status: 'INACTIVE',
        ),
      );

      expect(adapter.lastBody.containsKey('phoneNumber'), isFalse);
      expect(adapter.lastBody.containsKey('employeeId'), isFalse);
      expect(adapter.lastBody.containsKey('sendInviteEmail'), isFalse);
      expect(adapter.lastBody['createStatus'], 'INACTIVE');
    });

    test('sends password fields only for direct active creation', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter();
      dio.httpClientAdapter = adapter;
      final datasource = TenantUserRemoteDatasource(dio);

      await datasource.createUser(
        const UserWriteRequestDto(
          fullName: 'Direct User',
          email: 'direct@oneverz.com',
          roleId: 'role-1',
          status: 'ACTIVE',
          password: 'SecurePass123',
          confirmPassword: 'SecurePass123',
        ),
      );

      expect(adapter.lastBody['createStatus'], 'ACTIVE');
      expect(adapter.lastBody['password'], 'SecurePass123');
      expect(adapter.lastBody['confirmPassword'], 'SecurePass123');
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  String? lastPath;
  Map<String, dynamic> lastHeaders = const {};
  Map<String, dynamic> lastBody = const {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastHeaders = Map<String, dynamic>.from(options.headers);
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = chunks.expand((chunk) => chunk).toList();
      if (bytes.isNotEmpty) {
        lastBody = Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)));
      }
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'userId': 'user-1',
          'fullName': 'Kavin Perera',
          'email': 'kavin@oneverz.com',
          'roleName': 'Store Manager',
          'outlets': [],
          'status': 'INVITED',
          'permissionOverrideEnabled': false,
          'overriddenPermissionIds': [],
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
