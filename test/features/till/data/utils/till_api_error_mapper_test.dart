import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_error_message.dart';
import 'package:nytroz_pos/features/till/data/utils/till_api_error_mapper.dart';

void main() {
  test('error mapper reuses shared message and preserves code opt-out', () {
    final error = DioException(
        requestOptions: RequestOptions(path: '/till'),
        response: Response(
            requestOptions: RequestOptions(),
            statusCode: 409,
            data: {
              'errorCode': 'till_session.already_open',
              'message': 'Already open'
            }));
    expect(
        tillErrorMessage(error),
        messageFromDioException(error,
            contextPrefix: 'Till request failed at /till',
            fallback: 'Try again.'));
    expect(mapTillDioException(error).code, 'till_session.already_open');
    expect(mapTillDioException(error, includeCode: false).code, isNull);
    expect(
        tillErrorCode(DioException(requestOptions: RequestOptions())), isNull);
  });
}
