import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/pos_customer.dart';
import 'customer_search_provider.dart';

/// Raised when the Quick Add form cannot create a customer. Carries a
/// user-facing message (backend message when available) for the form to show.
class CustomerRegistrationException implements Exception {
  const CustomerRegistrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Controller for the Quick Add New Customer form.
///
/// Creates a tenant-scoped customer through the backend create API
/// (`POST /api/v1/customers`), attaches the saved customer to the current sale
/// selection and refreshes the recent/search list. No local-only or faked save.
class CustomerRegistrationController {
  const CustomerRegistrationController(this._ref);

  final Ref _ref;

  Future<PosCustomer> createAndAttach({
    required String fullName,
    required String dialCode,
    required String phoneNumber,
    String? email,
    DateTime? dateOfBirth,
  }) async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      throw const CustomerRegistrationException(
        'Device or session is not ready. Reactivate the device and try again.',
      );
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);

    final trimmedEmail = email?.trim();
    final phone = '${dialCode.trim()} ${phoneNumber.trim()}'.trim();

    try {
      final customer = await _ref.read(createPosCustomerProvider).call(
            deviceId: deviceContext.deviceId,
            fullName: fullName.trim(),
            phone: phone,
            email: (trimmedEmail == null || trimmedEmail.isEmpty)
                ? null
                : trimmedEmail,
          );

      _ref.read(selectedCustomerProvider.notifier).state = customer;
      _ref.invalidate(customerSearchResultsProvider);
      return customer;
    } on DioException catch (error) {
      throw CustomerRegistrationException(_messageFromDioError(error));
    }
  }

  String _messageFromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      if (message.isNotEmpty) {
        return message;
      }
    }

    return 'Could not save the customer. Please check the details and try again.';
  }
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

final customerRegistrationControllerProvider =
    Provider<CustomerRegistrationController>(
  CustomerRegistrationController.new,
);
