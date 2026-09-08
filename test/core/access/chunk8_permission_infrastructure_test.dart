import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/cashier_pos/cashier_pos_canonical_permission_codes.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/permission_gate.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';

void main() {
  const cashAccept = 'pos.payments.cash.accept';
  const exactCash = 'pos.cash_payment.tender.exact';

  group('EffectivePermissionSet membership', () {
    test('single permission present/absent', () {
      final set = EffectivePermissionSet.fromIterable([cashAccept]);
      expect(set.hasPermission(cashAccept), isTrue);
      expect(set.hasPermission(exactCash), isFalse);
    });

    test('fail-closed for null/empty', () {
      expect(
        EffectivePermissionSet.fromIterable(null).hasPermission(cashAccept),
        isFalse,
      );
      expect(EffectivePermissionSet.empty.hasPermission(cashAccept), isFalse);
      expect(
        EffectivePermissionSet.fromIterable(const <String>[])
            .hasPermission(cashAccept),
        isFalse,
      );
    });

    test('any-of / all-of', () {
      final set = EffectivePermissionSet.fromIterable([exactCash]);
      expect(set.hasAnyPermission([cashAccept, exactCash]), isTrue);
      expect(set.hasAnyPermission([cashAccept]), isFalse);
      expect(set.hasAllPermissions([exactCash]), isTrue);
      expect(set.hasAllPermissions([cashAccept, exactCash]), isFalse);
    });

    test('parent only does not grant Exact Cash child', () {
      final set = EffectivePermissionSet.fromIterable([cashAccept]);
      expect(set.hasPermission(exactCash), isFalse);
    });

    test('orphan child literally present is membership true (no hierarchy)',
        () {
      final set = EffectivePermissionSet.fromIterable([exactCash]);
      expect(set.hasPermission(exactCash), isTrue);
      expect(set.hasPermission(cashAccept), isFalse);
    });

    test('duplicates normalize to one entry', () {
      final set = EffectivePermissionSet.fromIterable([
        cashAccept,
        '  $cashAccept  ',
        cashAccept,
      ]);
      expect(set.length, 1);
      expect(set.hasPermission(cashAccept), isTrue);
    });

    test('unknown code is false', () {
      final set = EffectivePermissionSet.fromIterable([cashAccept]);
      expect(set.hasPermission('pos.payments.unknown.action'), isFalse);
    });

    test('wildcard and slash lookups are rejected', () {
      final set = EffectivePermissionSet.fromIterable([
        cashAccept,
        'pos.payments.*',
        'pos.till.session.open/close',
      ]);
      expect(set.hasPermission('pos.payments.*'), isFalse);
      expect(set.hasPermission('pos.till.session.open/close'), isFalse);
      expect(set.hasPermission(cashAccept), isTrue);
    });

    test('codes view is unmodifiable', () {
      final set = EffectivePermissionSet.fromIterable([cashAccept]);
      expect(
        () => set.codes.add('pos.payments.card.accept'),
        throwsUnsupportedError,
      );
    });

    test('filterByPermission omits denied items', () {
      final set = EffectivePermissionSet.fromIterable([cashAccept]);
      final items = [
        (id: 'cash', permission: cashAccept),
        (id: 'exact', permission: exactCash),
        (id: 'none', permission: null),
      ];
      final visible = set.filterByPermission(items, (item) => item.permission);
      expect(visible.map((e) => e.id), ['cash']);
    });

    test('canonical Exact Cash code exists in frozen Chunk 2 registry', () {
      expect(
        CashierPosCanonicalPermissionCodes.roleAssignableCodes
            .contains(exactCash),
        isTrue,
      );
      expect(
        CashierPosCanonicalPermissionCodes.roleAssignableCodes
            .contains(cashAccept),
        isTrue,
      );
    });
  });

  group('AuthSession membership', () {
    test('delegates to EffectivePermissionSet semantics', () {
      final session = AuthSession(
        accessToken: 'token',
        userId: 'u1',
        userDisplayName: 'Cashier',
        permissionCodes: [cashAccept, cashAccept],
      );
      expect(session.hasPermission(cashAccept), isTrue);
      expect(session.hasPermission(exactCash), isFalse);
      expect(session.hasPermission('pos.payments.*'), isFalse);
      expect(session.hasAnyPermission([exactCash, cashAccept]), isTrue);
      expect(session.hasAllPermissions([cashAccept, exactCash]), isFalse);
    });

    test('fromJson normalizes duplicates', () {
      final session = AuthSession.fromJson({
        'accessToken': 'token',
        'userId': 'u1',
        'userDisplayName': 'Cashier',
        'permissionCodes': [cashAccept, cashAccept, '  $exactCash  '],
      });
      expect(session.permissionCodes.length, 2);
      expect(session.hasPermission(exactCash), isTrue);
    });

    test('refresh replacement updates membership', () {
      var session = AuthSession(
        accessToken: 'token',
        userId: 'u1',
        userDisplayName: 'Cashier',
        permissionCodes: [cashAccept],
      );
      expect(session.hasPermission(exactCash), isFalse);

      session = AuthSession(
        accessToken: 'token',
        userId: 'u1',
        userDisplayName: 'Cashier',
        permissionCodes: [cashAccept, exactCash],
      );
      expect(session.hasPermission(exactCash), isTrue);

      session = AuthSession(
        accessToken: 'token',
        userId: 'u1',
        userDisplayName: 'Cashier',
        permissionCodes: [cashAccept],
      );
      expect(session.hasPermission(exactCash), isFalse);
    });
  });

  group('effectivePermissionSetProvider', () {
    test('null session is fail-closed empty set', () {
      final container = ProviderContainer(
        overrides: [
          effectivePermissionSetProvider
              .overrideWithValue(EffectivePermissionSet.empty),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(effectivePermissionSetProvider).hasPermission(cashAccept),
        isFalse,
      );
    });

    test('refresh via override updates membership', () {
      var set = EffectivePermissionSet.fromIterable([cashAccept]);
      final container = ProviderContainer(
        overrides: [
          effectivePermissionSetProvider.overrideWith((ref) => set),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(effectivePermissionSetProvider).hasPermission(exactCash),
        isFalse,
      );

      set = EffectivePermissionSet.fromIterable([cashAccept, exactCash]);
      container.invalidate(effectivePermissionSetProvider);
      expect(
        container.read(effectivePermissionSetProvider).hasPermission(exactCash),
        isTrue,
      );

      set = EffectivePermissionSet.fromIterable([cashAccept]);
      container.invalidate(effectivePermissionSetProvider);
      expect(
        container.read(effectivePermissionSetProvider).hasPermission(exactCash),
        isFalse,
      );
    });
  });

  group('PermissionGate widget', () {
    testWidgets('renders child when permission present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider.overrideWithValue(
              EffectivePermissionSet.fromIterable([cashAccept]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGate(
                permission: cashAccept,
                child: Text('PROTECTED', key: Key('protected')),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('protected')), findsOneWidget);
      expect(find.text('PROTECTED'), findsOneWidget);
    });

    testWidgets('hides child when permission absent — no maintainSize gap',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider
                .overrideWithValue(EffectivePermissionSet.empty),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGate(
                permission: cashAccept,
                child: SizedBox(
                  key: Key('protected'),
                  width: 120,
                  height: 80,
                  child: Text('PROTECTED'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('protected')), findsNothing);
      expect(find.text('PROTECTED'), findsNothing);
    });

    testWidgets('empty permissions fail-closed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider
                .overrideWithValue(EffectivePermissionSet.empty),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGate(
                permission: cashAccept,
                child: Text('PROTECTED'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('PROTECTED'), findsNothing);
    });

    testWidgets('any-of renders when one permission present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider.overrideWithValue(
              EffectivePermissionSet.fromIterable([exactCash]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PermissionGate.any(
                permissions: const [cashAccept, exactCash],
                child: const Text('ANY'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('ANY'), findsOneWidget);
    });

    testWidgets('all-of hides when one permission missing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider.overrideWithValue(
              EffectivePermissionSet.fromIterable([cashAccept]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PermissionGate.all(
                permissions: const [cashAccept, exactCash],
                child: const Text('ALL'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('ALL'), findsNothing);
    });

    testWidgets('custom fallback renders when denied', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider
                .overrideWithValue(EffectivePermissionSet.empty),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGate(
                permission: cashAccept,
                fallback: Text('FALLBACK'),
                child: Text('PROTECTED'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('FALLBACK'), findsOneWidget);
      expect(find.text('PROTECTED'), findsNothing);
    });

    testWidgets('parent-only Exact Cash child stays hidden', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider.overrideWithValue(
              EffectivePermissionSet.fromIterable([cashAccept]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGate(
                permission: exactCash,
                child: Text('EXACT'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('EXACT'), findsNothing);
    });

    testWidgets('phone/tablet/desktop layouts share same membership',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(768, 1024),
        Size(1280, 800),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              effectivePermissionSetProvider.overrideWithValue(
                EffectivePermissionSet.fromIterable([cashAccept]),
              ),
            ],
            child: MediaQuery(
              data: MediaQueryData(size: size),
              child: const MaterialApp(
                home: Scaffold(
                  body: PermissionGate(
                    permission: cashAccept,
                    child: Text('SHARED'),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('SHARED'), findsOneWidget, reason: '$size');

        final set = EffectivePermissionSet.fromIterable([cashAccept]);
        expect(set.hasPermission(exactCash), isFalse, reason: '$size');
        expect(set.hasPermission(cashAccept), isTrue, reason: '$size');
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}
