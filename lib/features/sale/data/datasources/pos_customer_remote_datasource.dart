import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/pos_customer.dart';

class PosCustomerRemoteDatasource {
  const PosCustomerRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<PosCustomer>> searchCustomers({
    required String deviceId,
    String? search,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posCustomers,
        queryParameters: {
          'deviceId': deviceId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(PosCustomer.fromJson)
            .toList(growable: false);
      }

      return [];
    } on DioException catch (error) {
      developer.log(
        'Customer search API failed. endpoint=${ApiEndpoints.posCustomers}, '
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

  Object _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is List) {
      return data;
    }

    return json;
  }
}
