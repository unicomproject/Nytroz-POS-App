import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/pos_customer.dart';
import '../../domain/entities/pos_customer_page.dart';

class PosCustomerRemoteDatasource {
  const PosCustomerRemoteDatasource(this._dio);

  final Dio _dio;

  /// Legacy helper used by New Sale customer dialog.
  Future<List<PosCustomer>> searchCustomers({
    required String deviceId,
    String? search,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    final result = await listCustomers(
      deviceId: deviceId,
      search: search,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    );
    return result.items;
  }

  Future<PosCustomerPage> listCustomers({
    required String deviceId,
    String? search,
    String? status,
    String? source,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posCustomers,
        queryParameters: {
          'deviceId': deviceId,
          'page': page < 1 ? 1 : page,
          'pageSize': pageSize < 1 ? 20 : pageSize,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
          if (source != null && source.trim().isNotEmpty)
            'source': source.trim(),
        },
        cancelToken: cancelToken,
      );

      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      final pagination = root['pagination'];

      if (data is List) {
        final map = <String, dynamic>{
          'items': data,
          if (pagination is Map) ...Map<String, dynamic>.from(pagination),
        };
        return PosCustomerPage.fromJson(map);
      }

      if (data is Map<String, dynamic>) {
        return PosCustomerPage.fromJson(data);
      }

      return PosCustomerPage(
        items: const [],
        page: page < 1 ? 1 : page,
        pageSize: pageSize < 1 ? 20 : pageSize,
        totalCount: 0,
        totalPages: 0,
      );
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        developer.log(
          'Customer list API failed. endpoint=${ApiEndpoints.posCustomers}, '
          'status=${error.response?.statusCode ?? 'none'}',
          name: 'pos.customer',
        );
      }
      rethrow;
    }
  }

  Future<PosCustomerSummary> getSummary({required String deviceId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posCustomersSummary,
        queryParameters: {'deviceId': deviceId},
      );
      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return PosCustomerSummary.fromJson(data);
      }
      throw StateError('Unexpected customer summary response.');
    } on DioException catch (error) {
      developer.log(
        'Customer summary API failed. endpoint=${ApiEndpoints.posCustomersSummary}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.customer',
      );
      rethrow;
    }
  }

  Future<PosCustomer> getCustomer({
    required String deviceId,
    required String customerId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posCustomer(customerId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );
      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return PosCustomer.fromJson(data);
      }
      throw StateError('Unexpected customer detail response.');
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        developer.log(
          'Customer detail API failed. endpoint=${ApiEndpoints.posCustomer(customerId)}, '
          'status=${error.response?.statusCode ?? 'none'}',
          name: 'pos.customer',
        );
      }
      rethrow;
    }
  }

  Future<List<PosCustomerOrder>> getCustomerOrders({
    required String deviceId,
    required String customerId,
    int page = 1,
    int pageSize = 5,
    CancelToken? cancelToken,
  }) async {
    final result = await getCustomerOrdersPage(
      deviceId: deviceId,
      customerId: customerId,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    );
    return result.items;
  }

  Future<PosCustomerOrderPage> getCustomerOrdersPage({
    required String deviceId,
    required String customerId,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posCustomerOrders(customerId),
        queryParameters: {
          'deviceId': deviceId,
          'page': page < 1 ? 1 : page,
          'pageSize': pageSize < 1 ? 20 : pageSize,
        },
        cancelToken: cancelToken,
      );

      final root = response.data ?? const {};
      final data = root['data'];
      final pagination = root['pagination'];

      if (data is List) {
        final map = <String, dynamic>{
          'items': data,
          if (pagination is Map) ...Map<String, dynamic>.from(pagination),
        };
        return PosCustomerOrderPage.fromJson(map);
      }

      if (data is Map<String, dynamic>) {
        return PosCustomerOrderPage.fromJson(data);
      }

      return PosCustomerOrderPage(
        items: const [],
        page: page < 1 ? 1 : page,
        pageSize: pageSize < 1 ? 20 : pageSize,
        totalCount: 0,
        totalPages: 0,
      );
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        developer.log(
          'Customer orders API failed. endpoint=${ApiEndpoints.posCustomerOrders(customerId)}, '
          'status=${error.response?.statusCode ?? 'none'}',
          name: 'pos.customer',
        );
      }
      rethrow;
    }
  }

  Future<PosCustomerAttachResult> attachToSale({
    required String deviceId,
    required String customerId,
    String? saleId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCustomerAttachToSale(customerId),
        queryParameters: {'deviceId': deviceId},
        data: {
          if (saleId != null && saleId.trim().isNotEmpty)
            'saleId': saleId.trim(),
        },
      );
      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return PosCustomerAttachResult.fromJson(data);
      }
      throw StateError('Unexpected customer attach response.');
    } on DioException catch (error) {
      developer.log(
        'Customer attach API failed. endpoint=${ApiEndpoints.posCustomerAttachToSale(customerId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.customer',
      );
      rethrow;
    }
  }

  Future<PosCustomer> createCustomer({
    required String deviceId,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCustomers,
        queryParameters: {'deviceId': deviceId},
        data: {
          'fullName': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return PosCustomer.fromJson(data);
      }

      throw StateError('Unexpected customer create response.');
    } on DioException catch (error) {
      developer.log(
        'Customer create API failed. endpoint=${ApiEndpoints.posCustomers}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.customer',
      );
      rethrow;
    }
  }

  Future<PosCustomer> updateCustomer({
    required String deviceId,
    required String customerId,
    required String fullName,
    String? phone,
    String? email,
    required String status,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.posCustomer(customerId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'fullName': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          'status': status,
        },
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return PosCustomer.fromJson(data);
      }

      throw StateError('Unexpected customer update response.');
    } on DioException catch (error) {
      developer.log(
        'Customer update API failed. endpoint=${ApiEndpoints.posCustomer(customerId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.customer',
      );
      rethrow;
    }
  }

  Object _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is List) {
      return data;
    }

    // List endpoint returns data as array with sibling pagination.
    if (json.containsKey('pagination') && data is List) {
      return {
        'items': data,
        'page': json['pagination']?['page'],
        'pageSize': json['pagination']?['pageSize'],
        'totalCount': json['pagination']?['totalCount'],
        'totalPages': json['pagination']?['totalPages'],
      };
    }

    return json;
  }
}
