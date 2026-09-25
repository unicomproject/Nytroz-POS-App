import 'package:dio/dio.dart';

import '../../../../core/network/dio_error_message.dart';
import '../../domain/entities/open_till.dart';

String tillErrorMessage(DioException error) {
  return messageFromDioException(
    error,
    contextPrefix: 'Till request failed at ${error.requestOptions.path}',
    fallback: 'Try again.',
  );
}

String? tillErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map) return null;
  return (data['code'] ?? data['errorCode'])?.toString();
}

/// Close Till historically exposes only the message, without an error code.
TillException mapTillDioException(DioException error,
    {bool includeCode = true}) {
  return TillException(tillErrorMessage(error),
      code: includeCode ? tillErrorCode(error) : null);
}
