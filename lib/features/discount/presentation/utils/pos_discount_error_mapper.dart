import 'dart:math';

import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';

/// Formats backend or internal errors into safe, cashier-friendly messages.
String safePosDiscountErrorMessage(Object error) {
  if (error is PosCheckoutApiException) {
    return switch (error.code) {
      'pos_discounts.permission_denied' =>
        'You do not have permission to apply discounts.',
      'pos_discounts.device_not_found' ||
      'pos_discounts.device_not_trusted' =>
        'This POS device is not authorized for discounts.',
      'pos_discounts.till_not_assigned' ||
      'pos_discounts.till_session_not_open' =>
        'An assigned till with an open session is required.',
      'pos_discounts.item_fixed_not_allowed' =>
        'Fixed amount discounts are not available for individual items.',
      'pos_discounts.target_required' ||
      'pos_discounts.target_not_in_cart' =>
        'Select a valid item from the current cart.',
      'pos_discounts.active_discount_exists' =>
        'Only one active discount is allowed. Remove the current discount first.',
      'pos_discounts.idempotency_conflict' =>
        'This discount request changed. Close and start a new discount request.',
      'pos_discounts.cart_changed' =>
        'The cart changed. Revalidate the discount and try again.',
      _ => error.isNetworkUnavailable
          ? 'Discount service is unavailable. Check the connection and try again.'
          : error.message,
    };
  }
  if (error is StateError) return error.message;
  return 'Unable to process the discount. Try again.';
}

/// Generates a cryptographically randomized, stable idempotency key for discount intents.
String createPosDiscountIdempotencyKey(String deviceId) {
  final random = Random.secure();
  final suffix =
      List.generate(12, (_) => random.nextInt(16).toRadixString(16)).join();
  return '$deviceId-${DateTime.now().microsecondsSinceEpoch}-$suffix';
}
