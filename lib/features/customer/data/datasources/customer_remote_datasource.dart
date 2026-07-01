import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/pos_customer.dart';
import '../models/pos_customer_dto.dart';

/// Talks to the tenant-scoped POS customer API (`/api/v1/customers`).
///
/// The backend enforces tenant, feature entitlement, permission and trusted
/// device/till rules; this datasource only forwards the active `deviceId` and
/// maps the JSON envelope (`{ success, message, data }`).
class CustomerRemoteDatasource {
  const CustomerRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<PosCustomer>> searchCustomers({
    required String deviceId,
    String? query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.customers,
      queryParameters: {
        'deviceId': deviceId,
        if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
      },
    );

    return _unwrapList(response.data ?? const {})
        .map((item) => PosCustomerDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<PosCustomer> createCustomer({
    required String deviceId,
    required String fullName,
    required String phone,
    String? email,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.customers,
      queryParameters: {'deviceId': deviceId},
      data: <String, dynamic>{
        'fullName': fullName,
        'phone': phone,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );

    return PosCustomerDto.fromJson(_unwrapMap(response.data ?? const {}));
  }

  List<dynamic> _unwrapList(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data;
    }

    return const [];
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return json;
  }
}
