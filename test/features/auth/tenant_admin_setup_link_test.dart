import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/deep_link/tenant_admin_setup_link.dart';

void main() {
  test('native invitation decodes token exactly once', () {
    final link = TenantAdminSetupLink.parse(
        Uri.parse('oneverz://tenant-admin/setup?token=abc%2B%2F%3D'));
    expect(link?.setupToken, 'abc+/=');
    expect(link?.location, '/tenant-admin/setup/abc%2B%2F%3D');
  });
  for (final uri in [
    'https://tenant-admin/setup?token=abc',
    'oneverz://other/setup?token=abc',
    'oneverz://tenant-admin/other?token=abc',
    'oneverz://tenant-admin/setup',
    'oneverz://tenant-admin/setup?token=',
    'oneverz://tenant-admin/setup?token=a&token=b',
    'oneverz://tenant-admin/setup?token=a&email=x',
    'oneverz://tenant-admin/setup?token=%20abc',
    'oneverz://tenant-admin/setup?token=%00',
    'oneverz://tenant-admin/setup?token=%ZZ',
    'oneverz://user@tenant-admin/setup?token=a',
    'oneverz://tenant-admin:42/setup?token=a',
    'oneverz://tenant-admin/setup?token=a#fragment',
  ]) {
    test('rejects malformed invitation $uri', () {
      expect(TenantAdminSetupLink.parse(Uri.parse(uri)), isNull);
    });
  }

  for (final cold in [true, false]) {
    testWidgets('${cold ? 'cold' : 'warm'} platform link reaches setup',
        (tester) async {
      const incoming = 'oneverz://tenant-admin/setup?token=abc123';
      tester.platformDispatcher.defaultRouteNameTestValue =
          cold ? incoming : '/';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final router = GoRouter(
        initialLocation: '/boot',
        overridePlatformDefaultLocation: false,
        redirect: (_, state) => TenantAdminSetupLink.redirect(state.uri),
        routes: [
          GoRoute(path: '/boot', builder: (_, __) => const Text('Normal boot')),
          GoRoute(
              path: '/tenant-admin/setup/:token',
              builder: (_, state) =>
                  Text('Setup ${state.pathParameters['token']}')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      if (!cold) {
        expect(find.text('Normal boot'), findsOneWidget);
        await router.routeInformationProvider.didPushRouteInformation(
            RouteInformation(uri: Uri.parse(incoming)));
        await tester.pumpAndSettle();
      }
      expect(find.text('Setup abc123'), findsOneWidget);
    });
  }
}
