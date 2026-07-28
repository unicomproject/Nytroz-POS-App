import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/app/router/app_router.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/post_login_navigation_provider.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_bootstrap_provider.dart';

void main() {
  group('cold-start routing', () {
    test('waits on bootstrap while auth storage is hydrating', () {
      expect(
        _redirect(
          path: '/pos/returns-refunds/receipt',
          hydrated: false,
          authenticated: false,
          bootstrapReady: false,
        ),
        posSessionBootRoute,
      );
    });

    test('routes to login after hydration finds no valid session', () {
      expect(
        _redirect(
          path: posSessionBootRoute,
          hydrated: true,
          authenticated: false,
          bootstrapReady: false,
        ),
        '/tenant-login',
      );
    });

    test('routes valid login with unpaired device to device activation', () {
      expect(
        _redirect(
          path: posSessionBootRoute,
          authenticatedRoute: PostLoginRoute.deviceActivation.path,
        ),
        PostLoginRoute.deviceActivation.path,
      );
    });

    test('routes valid login without open till to open till', () {
      expect(
        _redirect(
          path: posSessionBootRoute,
          authenticatedRoute: PostLoginRoute.openTill.path,
        ),
        PostLoginRoute.openTill.path,
      );
    });

    test('routes valid completed setup to POS home', () {
      expect(
        _redirect(path: posSessionBootRoute),
        PostLoginRoute.posHome.path,
      );
    });

    test('preserves tenant admin deep links for tenant admin sessions', () {
      expect(
        _redirect(
          path: '/tenant-admin/roles-permissions',
          authenticatedRoute: PostLoginRoute.tenantAdminRoot.path,
        ),
        isNull,
      );
    });

    test('routes POS paths back to tenant admin shell for tenant sessions', () {
      expect(
        _redirect(
          path: '/pos/home',
          authenticatedRoute: PostLoginRoute.tenantAdminRoot.path,
        ),
        PostLoginRoute.tenantAdminRoot.path,
      );
    });

    test('routes users without an app route to tenant no-access', () {
      expect(
        _redirect(
          path: posSessionBootRoute,
          authenticatedRoute: PostLoginRoute.tenantAdminNoAccess.path,
        ),
        PostLoginRoute.tenantAdminNoAccess.path,
      );
    });

    test('routes POS users without an app route to POS no-access', () {
      expect(
        _redirect(
          path: posSessionBootRoute,
          authenticatedRoute: PostLoginRoute.posNoAccess.path,
        ),
        PostLoginRoute.posNoAccess.path,
      );
    });

    test('routes tenant-admin paths back to POS no-access for POS sessions',
        () {
      expect(
        _redirect(
          path: '/tenant-admin/no-access',
          authenticatedRoute: PostLoginRoute.posNoAccess.path,
        ),
        PostLoginRoute.posNoAccess.path,
      );
    });

    test('ignores Returns and Payment locations during cold start', () {
      for (final nestedRoute in [
        '/pos/returns-refunds/settlement',
        '/pos/new-sale/payment/cash',
      ]) {
        expect(
          _redirect(
            path: nestedRoute,
            hydrated: false,
            authenticated: true,
            bootstrapReady: false,
          ),
          posSessionBootRoute,
        );
      }
    });

    test('preserves an active nested route after background resume', () {
      expect(
        _redirect(path: '/pos/returns-refunds/eligibility'),
        isNull,
      );
    });

    test('does not create a bootstrap redirect loop', () {
      expect(
        _redirect(
          path: posSessionBootRoute,
          hydrated: false,
          authenticated: false,
          bootstrapReady: false,
        ),
        isNull,
      );
      expect(
        _redirect(path: PostLoginRoute.posHome.path),
        isNull,
      );
    });

    test('preserves intentional tenant setup deep links', () {
      expect(
        _redirect(
          path: '/tenant-admin/setup/token/validate',
          hydrated: false,
          authenticated: false,
          bootstrapReady: false,
        ),
        isNull,
      );
    });
  });
}

String? _redirect({
  required String path,
  bool hydrated = true,
  bool authenticated = true,
  bool bootstrapReady = true,
  String authenticatedRoute = '/pos/home',
}) {
  return resolveAppRedirect(
    path: path,
    authSessionHydrated: hydrated,
    isAuthenticated: authenticated,
    bootstrapReady: bootstrapReady,
    authenticatedInitialRoute: authenticatedRoute,
  );
}
