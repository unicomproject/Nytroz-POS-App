import 'package:dio/dio.dart';

const kDefaultReviewPackErrorMessage =
    'Unable to mark this order ready for collection.';

/// Maps a [DioException] from the pack or mark-ready actions into a
/// user-facing error message.
String mapReviewPackError(DioException error) {
  final code = error.response?.data is Map
      ? (error.response!.data as Map)['errorCode']?.toString()
      : null;
  return switch (code) {
    'online_orders.concurrency_conflict' =>
      'This order changed. Refresh and try again.',
    'online_orders.not_packable' =>
      'This order is not eligible to pack yet.',
    'online_orders.not_readyable' =>
      'This order must be packed before it can be marked ready.',
    'online_orders.permission_denied' =>
      'You do not have permission for this action.',
    'online_orders.invalid_packing_note' =>
      'Packing note is invalid.',
    _ => error.response?.statusCode == 409
        ? 'This order changed. Refresh and try again.'
        : kDefaultReviewPackErrorMessage,
  };
}

/// Safe helper mapping any caught exception during Review & Pack submission.
String mapReviewPackException(Object error) {
  if (error is DioException) {
    return mapReviewPackError(error);
  }
  return kDefaultReviewPackErrorMessage;
}
