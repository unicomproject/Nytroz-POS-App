import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/data/datasources/outlet_remote_datasource.dart';

void main() {
  group('OutletRemoteDatasource tenant-admin integrations', () {
    late _OutletApiAdapter adapter;
    late OutletRemoteDatasource datasource;

    setUp(() {
      final dio = Dio();
      adapter = _OutletApiAdapter();
      dio.httpClientAdapter = adapter;
      datasource = OutletRemoteDatasource(dio);
    });

    test('loads revenue, assigned users and tills from real detail routes',
        () async {
      final revenue = await datasource.getOutletRevenueSummary('outlet-1');
      final users = await datasource.getOutletAssignedUsers('outlet-1');
      final tills = await datasource.getOutletTillsDetail('outlet-1');

      expect(revenue.totalRevenue, 1250);
      expect(users.summary.totalAssignedUsers, 1);
      expect(users.items.single.displayName, 'Cashier One');
      expect(tills.summary.totalTills, 1);
      expect(tills.items.single.tillName, 'Front Till');
      expect(
        adapter.paths,
        containsAll([
          '/api/v1/tenant-admin/outlets/outlet-1/revenue-summary',
          '/api/v1/tenant-admin/outlets/outlet-1/users',
          '/api/v1/tenant-admin/outlets/outlet-1/tills',
        ]),
      );
    });

    test('loads manager options and uses manager command routes', () async {
      final managers = await datasource.getManagerOptions();
      await datasource.setOutletManager('outlet-1', 'user-1');
      await datasource.removeOutletManager('outlet-1');

      expect(managers.single.id, 'user-1');
      expect(managers.single.displayName, 'Store Manager');
      expect(adapter.requests[1].method, 'PUT');
      expect(adapter.requests[1].data, {'tenantUserId': 'user-1'});
      expect(adapter.requests[2].method, 'DELETE');
    });

    test('updates outlet lifecycle status without deleting the outlet',
        () async {
      await datasource.updateOutletStatus('outlet-1', 'INACTIVE');

      final request = adapter.requests.single;
      expect(request.path, '/api/v1/tenant-admin/outlets/outlet-1/status');
      expect(request.method, 'PUT');
      expect(request.data, {'status': 'INACTIVE'});
    });
  });
}

class _OutletApiAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  List<String> get paths => requests.map((request) => request.path).toList();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = switch (options.path) {
      '/api/v1/tenant-admin/outlets/outlet-1/revenue-summary' => {
          'totalRevenue': 1250,
          'averageOrderValue': 125,
          'totalOrders': 10,
          'refunds': 0,
          'revenueOverTime': <Object>[],
          'revenueByPaymentMethod': <Object>[],
          'revenueSummary': {
            'grossRevenue': 1250,
            'discounts': 0,
            'returns': 0,
            'netRevenue': 1250,
            'taxCollected': 0,
          },
        },
      '/api/v1/tenant-admin/outlets/outlet-1/users' => {
          'summary': {
            'totalAssignedUsers': 1,
            'activeUsers': 1,
            'pendingInvites': 0,
            'managers': 0,
          },
          'items': [
            {
              'userId': 'user-2',
              'displayName': 'Cashier One',
              'roleName': 'Cashier',
              'status': 'ACTIVE',
            },
          ],
        },
      '/api/v1/tenant-admin/outlets/outlet-1/tills' => {
          'summary': {
            'totalTills': 1,
            'activeTills': 1,
            'currentlyOpenTills': 1,
            'tillsNeedingAttention': 0,
          },
          'items': [
            {
              'tillId': 'till-1',
              'tillName': 'Front Till',
              'tillCode': 'T01',
              'status': 'ACTIVE',
              'deviceStatus': 'Online',
            },
          ],
        },
      '/api/v1/tenant-admin/outlets/manager-options' => [
          {
            'tenantUserId': 'user-1',
            'displayName': 'Store Manager',
            'email': 'manager@example.com',
          },
        ],
      _ => <String, Object?>{},
    };

    return ResponseBody.fromString(
      jsonEncode({'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
