import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/api_config.dart';

void main() {
  group('ApiConfig.resolveBaseUrl', () {
    test('explicit API_BASE_URL has highest precedence', () async {
      final result = await ApiConfig.resolveBaseUrl(
        apiBaseUrl: 'https://api.example.com/',
        pcLanIp: '192.168.18.8',
        targetPlatform: TargetPlatform.android,
        isPhysicalDevice: true,
        isReleaseMode: true,
      );

      expect(result, 'https://api.example.com');
    });

    test('PC_LAN_IP creates the backend HTTP URL', () async {
      final result = await ApiConfig.resolveBaseUrl(
        pcLanIp: '192.168.18.8',
        targetPlatform: TargetPlatform.android,
        isPhysicalDevice: true,
        isReleaseMode: false,
      );

      expect(result, 'http://192.168.18.8:$kBackendHttpPort');
    });

    test('Android emulator uses the emulator development fallback', () async {
      final result = await ApiConfig.resolveBaseUrl(
        targetPlatform: TargetPlatform.android,
        isPhysicalDevice: false,
        isReleaseMode: false,
      );

      expect(result, 'http://10.0.2.2:$kBackendHttpPort');
    });

    test('Windows desktop uses localhost development fallback', () async {
      final result = await ApiConfig.resolveBaseUrl(
        targetPlatform: TargetPlatform.windows,
        isReleaseMode: false,
      );

      expect(result, 'http://localhost:$kBackendHttpPort');
    });

    test('invalid API_BASE_URL is rejected', () async {
      expect(
        () => ApiConfig.resolveBaseUrl(
          apiBaseUrl: 'not-a-url',
          targetPlatform: TargetPlatform.windows,
          isReleaseMode: false,
        ),
        throwsA(isA<ApiConfigurationException>()),
      );
    });

    test('physical Android without configuration fails clearly', () async {
      expect(
        () => ApiConfig.resolveBaseUrl(
          targetPlatform: TargetPlatform.android,
          isPhysicalDevice: true,
          isReleaseMode: false,
        ),
        throwsA(
          isA<ApiConfigurationException>().having(
            (error) => error.message,
            'message',
            contains('physical Android'),
          ),
        ),
      );
    });

    test('trailing slashes are normalized', () async {
      final result = await ApiConfig.resolveBaseUrl(
        apiBaseUrl: 'https://api.example.com/pos///',
        targetPlatform: TargetPlatform.windows,
        isReleaseMode: false,
      );

      expect(result, 'https://api.example.com/pos');
    });

    test('release build rejects development fallback', () async {
      expect(
        () => ApiConfig.resolveBaseUrl(
          targetPlatform: TargetPlatform.windows,
          isReleaseMode: true,
        ),
        throwsA(
          isA<ApiConfigurationException>().having(
            (error) => error.message,
            'message',
            contains('release builds'),
          ),
        ),
      );
    });

    test('invalid PC_LAN_IP is rejected', () async {
      expect(
        () => ApiConfig.resolveBaseUrl(
          pcLanIp: '192.168.18.999',
          targetPlatform: TargetPlatform.android,
          isPhysicalDevice: true,
          isReleaseMode: false,
        ),
        throwsA(isA<ApiConfigurationException>()),
      );
    });
  });
}
