import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/auth_unauthorized_interceptor.dart';

void main() {
  test('concurrent 401 responses share one refresh and retry each request once',
      () async {
    final adapter = _ProtectedResourceAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://pos.test'))
      ..httpClientAdapter = adapter;
    var refreshCalls = 0;
    var rejectedCalls = 0;

    dio.interceptors.add(AuthUnauthorizedInterceptor(
      dio: dio,
      refreshAccessToken: () async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'rotated-access-token';
      },
      onRefreshRejected: () async => rejectedCalls++,
    ));

    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/protected/one'),
      dio.get<Map<String, dynamic>>('/protected/two'),
    ]);

    expect(refreshCalls, 1);
    expect(rejectedCalls, 0);
    expect(adapter.initialCalls, 2);
    expect(adapter.retryCalls, 2);
    expect(responses.map((response) => response.statusCode), everyElement(200));
  });

  test('a retried 401 is not refreshed or retried again', () async {
    final adapter = _AlwaysUnauthorizedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://pos.test'))
      ..httpClientAdapter = adapter;
    var refreshCalls = 0;
    var rejectedCalls = 0;

    dio.interceptors.add(AuthUnauthorizedInterceptor(
      dio: dio,
      refreshAccessToken: () async {
        refreshCalls++;
        return 'rotated-access-token';
      },
      onRefreshRejected: () async => rejectedCalls++,
    ));

    await expectLater(
      dio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 1);
    expect(rejectedCalls, 1);
    expect(adapter.calls, 2);
  });

  test('payment request marked no-retry is dispatched exactly once', () async {
    final adapter = _AlwaysUnauthorizedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://pos.test'))
      ..httpClientAdapter = adapter;
    var refreshCalls = 0;

    dio.interceptors.add(AuthUnauthorizedInterceptor(
      dio: dio,
      refreshAccessToken: () async {
        refreshCalls++;
        return 'rotated-access-token';
      },
      onRefreshRejected: () async {},
    ));

    await expectLater(
      dio.post<Map<String, dynamic>>(
        '/api/v1/pos/checkout/start-payment',
        options: Options(extra: const {
          AuthUnauthorizedInterceptor.disableAutomaticRetry: true,
        }),
      ),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 0);
    expect(adapter.calls, 1);
  });
}

class _ProtectedResourceAdapter implements HttpClientAdapter {
  int initialCalls = 0;
  int retryCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.headers['Authorization'] == 'Bearer rotated-access-token') {
      retryCalls++;
      return _jsonResponse(200, {'ok': true});
    }

    initialCalls++;
    return _jsonResponse(401, {'code': 'unauthorized'});
  }

  @override
  void close({bool force = false}) {}
}

class _AlwaysUnauthorizedAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return _jsonResponse(401, {'code': 'unauthorized'});
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
