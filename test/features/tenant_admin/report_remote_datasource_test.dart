import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/data/constants/report_api_paths.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/data/datasources/report_remote_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/domain/entities/report_models.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/domain/entities/report_query.dart';

void main() {
  test('uses the planned Tenant Admin sales report route', () async {
    final dio = Dio();
    final adapter = _ReportAdapter({
      'data': {
        'section': 'transactions',
        'items': [],
        'page': 1,
        'pageSize': 25,
        'totalCount': 0,
      },
    });
    dio.httpClientAdapter = adapter;

    final datasource = ReportRemoteDatasource(dio);
    await datasource.getSales(
      ReportQuery(
        from: DateTime(2026, 7, 1),
        to: DateTime(2026, 7, 15),
        section: ReportSections.transactions,
      ),
    );

    expect(adapter.lastPath, ReportApiPaths.sales);
    expect(adapter.lastQuery?['section'], ReportSections.transactions);
    expect(adapter.lastQuery?.containsKey('tenantId'), isFalse);
  });

  test('parses wrapped pagination and metrics', () async {
    final dio = Dio();
    dio.httpClientAdapter = _ReportAdapter({
      'data': {
        'section': 'summary',
        'metrics': [
          {'key': 'netSales', 'label': 'Net Sales', 'rawValue': 125.5},
        ],
        'items': [],
      },
      'page': 1,
      'pageSize': 25,
      'totalCount': 0,
      'totalPages': 0,
    });

    final result = await ReportRemoteDatasource(dio).getSales(
      const ReportQuery(section: ReportSections.salesSummary),
    );

    expect(result.metrics.single.key, 'netSales');
    expect(result.metrics.single.rawValue, 125.5);
    expect(result.pagination.pageSize, 25);
  });

  test('parses backend summary map as frontend metrics', () async {
    final dio = Dio();
    dio.httpClientAdapter = _ReportAdapter({
      'data': {
        'section': 'summary',
        'summary': {
          'netSales': 125.5,
          'transactionCount': 4,
        },
        'records': [],
        'pagination': {
          'page': 1,
          'pageSize': 25,
          'totalCount': 0,
          'totalPages': 0,
        },
      },
    });

    final result = await ReportRemoteDatasource(dio).getSales(
      const ReportQuery(section: ReportSections.salesSummary),
    );

    expect(result.metrics.map((metric) => metric.key), contains('netSales'));
    expect(result.metrics.map((metric) => metric.key),
        contains('transactionCount'));
  });

  test('parses backend sections map and filter option groups wrapper',
      () async {
    final dio = Dio();
    dio.httpClientAdapter = _ReportAdapter({
      'data': {
        'groups': {
          'outlets': [
            {
              'id': 'outlet-1',
              'code': 'OUT-001',
              'name': 'Main Outlet',
              'status': 'ACTIVE',
              'isActive': true,
            }
          ],
        },
      },
    });

    final options = await ReportRemoteDatasource(dio).getFilterOptions(
      const ReportQuery(section: ReportSections.transactions),
    );

    expect(options.groups['outlets']?.single.id, 'outlet-1');

    dio.httpClientAdapter = _ReportAdapter({
      'data': {
        'section': 'dashboard',
        'summary': {},
        'sections': {
          'salesTrend': [
            {'businessDate': '2026-07-16', 'netSalesAmount': 100},
          ],
        },
        'records': [],
      },
    });

    final dashboard = await ReportRemoteDatasource(dio).getDashboard(
      const ReportQuery(section: ReportSections.dashboard),
    );

    expect(dashboard.sections.single.key, 'salesTrend');
    expect(dashboard.sections.single.records.single['netSalesAmount'], 100);
  });

  test('sends export request without tenant authority or UI pagination',
      () async {
    final dio = Dio();
    final adapter = _ReportAdapter({
      'data': {
        'jobId': 'job-1',
        'reportType': 'sales',
        'format': 'CSV',
        'status': 'COMPLETED',
        'requestedAt': '2026-07-16T00:00:00Z',
      },
    });
    dio.httpClientAdapter = adapter;

    await ReportRemoteDatasource(dio).requestExport(
      ReportExportRequest(
        reportType: 'sales',
        section: ReportSections.transactions,
        format: 'csv',
        query: ReportQuery(
          from: DateTime(2026, 7, 1),
          to: DateTime(2026, 7, 16),
          section: ReportSections.transactions,
          page: 3,
        ),
      ),
    );

    expect(adapter.lastPath, ReportApiPaths.exports);
    expect(adapter.lastBody?['reportType'], 'sales');
    expect(adapter.lastBody?['section'], ReportSections.transactions);
    expect(adapter.lastBody?.containsKey('tenantId'), isFalse);
    expect(adapter.lastBody?.containsKey('page'), isFalse);
  });
}

class _ReportAdapter implements HttpClientAdapter {
  _ReportAdapter(this.payload);

  final Map<String, dynamic> payload;
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastQuery = Map<String, dynamic>.from(options.queryParameters);
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = chunks.expand((chunk) => chunk).toList();
      if (bytes.isNotEmpty) {
        lastBody = Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)));
      }
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
