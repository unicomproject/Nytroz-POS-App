import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';

void main() {
  test('preserves an absolute valid image URL', () {
    expect(
      MediaUrlResolver.resolve(
        'https://cdn.example.test/profile.jpg',
        apiBaseUrl: 'http://10.0.2.2:5150',
      ),
      'https://cdn.example.test/profile.jpg',
    );
  });

  test('resolves a relative media path against the API origin', () {
    expect(
      MediaUrlResolver.resolve(
        '/media/profiles/cashier.jpg',
        apiBaseUrl: 'http://10.0.2.2:5150/api',
      ),
      'http://10.0.2.2:5150/media/profiles/cashier.jpg',
    );
  });

  test('converts localhost to the Android API host in development', () {
    expect(
      MediaUrlResolver.resolve(
        'http://localhost:5150/media/profiles/cashier.jpg',
        apiBaseUrl: 'http://10.0.2.2:5150',
        replaceLoopbackHost: true,
      ),
      'http://10.0.2.2:5150/media/profiles/cashier.jpg',
    );
  });

  test('uses a physical-device LAN host from the configured API URL', () {
    expect(
      MediaUrlResolver.resolve(
        'http://127.0.0.1:5150/media/profiles/cashier.jpg',
        apiBaseUrl: 'http://192.168.18.8:5150',
        replaceLoopbackHost: true,
      ),
      'http://192.168.18.8:5150/media/profiles/cashier.jpg',
    );
  });

  test('returns null for null or empty values', () {
    expect(
      MediaUrlResolver.resolve(null, apiBaseUrl: 'http://10.0.2.2:5150'),
      isNull,
    );
    expect(
      MediaUrlResolver.resolve('  ', apiBaseUrl: 'http://10.0.2.2:5150'),
      isNull,
    );
  });
}
