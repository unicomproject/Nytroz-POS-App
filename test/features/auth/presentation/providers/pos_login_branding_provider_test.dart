
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/domain/entities/pos_login_branding.dart';
import 'package:nytroz_pos/features/auth/domain/repositories/pos_login_branding_repository.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/pos_login_branding_provider.dart';

class MockPosLoginBrandingRepository implements PosLoginBrandingRepository {
  Future<PosLoginBranding?> Function(String slug)? onReadCached;
  Future<PosLoginBranding> Function(String slug)? onRefresh;

  @override
  Future<PosLoginBranding?> readCached(String slug) async {
    return onReadCached?.call(slug);
  }

  @override
  Future<PosLoginBranding> refresh(String slug) async {
    return onRefresh != null
        ? onRefresh!(slug)
        : throw UnimplementedError();
  }
}

void main() {
  group('PosLoginBrandingController', () {
    late MockPosLoginBrandingRepository repository;
    late String resolvedTenantSlug;

    setUp(() {
      repository = MockPosLoginBrandingRepository();
      resolvedTenantSlug = 'test-tenant';
    });

    PosLoginBrandingController createController() {
      return PosLoginBrandingController(
        repository,
        () async => resolvedTenantSlug,
      );
    }

    test('normal load completes successfully', () async {
      final branding = PosLoginBranding(
        tenantSlug: 'test',
        brandDisplayName: 'test',
        systemName: 'test',
        description: 'test',
        loginSubtitle: 'test',
        backgroundMode: PosLoginBackgroundMode.color,
        backgroundColor: '#FFFFFF',
        updatedAt: DateTime.now(),
        logoUrl: 'logo.png',
      );

      repository.onReadCached = (_) async => null;
      repository.onRefresh = (_) async => branding;

      final controller = createController();
      
      // Wait for the async load to finish (we need to give it a microtask frame)
      await Future.delayed(Duration.zero);
      expect(controller.state, equals(branding));
    });

    test('error handling uses cache if available', () async {
      final cachedBranding = PosLoginBranding(
        tenantSlug: 'test',
        brandDisplayName: 'test',
        systemName: 'test',
        description: 'test',
        loginSubtitle: 'test',
        backgroundMode: PosLoginBackgroundMode.color,
        backgroundColor: '#FFFFFF',
        updatedAt: DateTime.now(),
        logoUrl: 'cached.png',
      );

      repository.onReadCached = (_) async => cachedBranding;
      repository.onRefresh = (_) async => throw Exception('Network error');

      final controller = createController();

      await Future.delayed(Duration.zero);
      expect(controller.state, equals(cachedBranding));
    });

    test('dispose during load prevents state update and unhandled exceptions', () async {
      final branding = PosLoginBranding(
        tenantSlug: 'test',
        brandDisplayName: 'test',
        systemName: 'test',
        description: 'test',
        loginSubtitle: 'test',
        backgroundMode: PosLoginBackgroundMode.color,
        backgroundColor: '#FFFFFF',
        updatedAt: DateTime.now(),
        logoUrl: 'delayed.png',
      );

      repository.onReadCached = (_) async => null;
      repository.onRefresh = (_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return branding;
      };

      final controller = createController();
      // Dispose immediately while the initial load is in progress.
      controller.dispose();

      // Wait for the async operation to complete.
      await Future.delayed(const Duration(milliseconds: 20));
      // State should not be updated (controller throws StateError if you access state after dispose, 
      // but we just verify it doesn't crash during the async completion).
      expect(true, isTrue); // If we reach here without crash, test passed.
    });

    test('error after dispose prevents state update and unhandled exceptions', () async {
      repository.onReadCached = (_) async => null;
      repository.onRefresh = (_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw Exception('Delayed network error');
      };

      final controller = createController();
      controller.dispose();

      await Future.delayed(const Duration(milliseconds: 20));
      expect(true, isTrue); // Reached without crash.
    });
  });
}
