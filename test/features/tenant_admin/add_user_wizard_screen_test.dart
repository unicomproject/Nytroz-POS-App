import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/tenant_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/screens/add_user_wizard_screen.dart';

void main() {
  group('AddUserWizardScreen five-step workflow', () {
    testWidgets('Step 1 contains identity fields and no role selector',
        (tester) async {
      await _pumpWizard(tester);

      expect(find.text('Add New User'), findsOneWidget);
      expect(find.text('Basic Information'), findsWidgets);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Employee ID (Optional)'), findsOneWidget);
      expect(find.text('Staff Code'), findsOneWidget);
      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Assign Role'), findsOneWidget);
      expect(find.text('Select role'), findsNothing);
    });

    testWidgets('active status reveals secure password fields',
        (tester) async {
      await _pumpWizard(tester);

      await tester.tap(find.text('Active'));
      await tester.pump();

      expect(find.text('Password *'), findsOneWidget);
      expect(find.text('Confirm Password *'), findsOneWidget);
      expect(
        find.text(
          'Minimum 8 characters with uppercase, lowercase, and a number. Only a secure password hash is stored.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tablet landscape shows the full five-step indicator',
        (tester) async {
      await _pumpWizard(tester, size: const Size(1024, 768));

      for (final label in const [
        'Basic Information',
        'Assign Role',
        'Configure Permissions',
        'Outlet, Till & Access Scope',
        'Security & Review',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('identity, role and permission steps are separate',
        (tester) async {
      await _toRoleStep(tester);
      expect(find.text('Store Manager'), findsWidgets);
      expect(find.text('Cashier'), findsOneWidget);

      await tester.tap(find.text('Store Manager').first);
      await tester.pump();
      await _tapVisible(tester, find.text('Next'));
      await tester.pump();

      expect(find.text('Configure Permissions'), findsWidgets);
      expect(find.text('Reporting'), findsOneWidget);
      expect(find.text('View Reports'), findsOneWidget);
    });

    testWidgets('Step 4 renders exact outlet and till scope controls',
        (tester) async {
      await _toRoleStep(tester);
      await tester.tap(find.text('Store Manager').first);
      await tester.pump();
      await _tapVisible(tester, find.text('Next'));
      await tester.pump();
      await _tapVisible(tester, find.text('Next'));
      await tester.pump();

      expect(find.text('Outlet Access'), findsOneWidget);
      expect(find.text('All Outlets'), findsOneWidget);
      expect(find.text('Selected Outlets'), findsOneWidget);
      expect(find.text('No Outlet Access'), findsOneWidget);
      expect(find.text('Till Access'), findsOneWidget);
      expect(find.text('All Accessible Tills'), findsOneWidget);
      expect(find.text('Selected Tills'), findsOneWidget);
      expect(find.text('No Till Access'), findsOneWidget);
    });

    testWidgets('all five steps render at 1024x768 without overflow',
        (tester) async {
      await _toRoleStep(tester, size: const Size(1024, 768));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Store Manager').first);
      await tester.pump();
      await _tapVisible(tester, find.text('Next'));
      await tester.pump();
      expect(find.text('Configure Permissions'), findsWidgets);
      expect(tester.takeException(), isNull);

      await _tapVisible(tester, find.text('Next'));
      await tester.pump();
      expect(find.text('Outlet Access'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tapVisible(tester, find.text('Next'));
      await tester.pump();
      expect(find.text('Security & Review'), findsWidgets);
      expect(find.text('Create User'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dirty cancel shows discard confirmation', (tester) async {
      await _pumpWizard(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Kavin Perera');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard user setup?'), findsOneWidget);
      expect(find.text('Continue editing'), findsOneWidget);
      expect(find.text('Discard and return to Users'), findsOneWidget);
    });

    testWidgets('compact layout has no immediate overflow', (tester) async {
      await _pumpWizard(tester, size: const Size(390, 900));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _toRoleStep(
  WidgetTester tester, {
  Size size = const Size(1200, 900),
}) async {
  await _pumpWizard(tester, size: size);
  await tester.enterText(find.byType(TextFormField).at(0), 'Kavin Perera');
  await tester.enterText(find.byType(TextFormField).at(2), 'kavin@oneverz.com');
  await _tapVisible(tester, find.text('Next'));
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _pumpWizard(
  WidgetTester tester, {
  Size size = const Size(1200, 900),
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(Dio()),
        tenantAdminAccessCheckerProvider
            .overrideWith((ref) async => _checker()),
        userCreateOptionsProvider.overrideWith((ref) async => _createOptions),
      ],
      child: const MaterialApp(
        home: Scaffold(body: AddUserWizardScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

const _createOptions = TenantUserCreateOptions(
  roles: [
    RoleOption(
      id: 'role-1',
      name: 'Store Manager',
      code: 'MGR',
      roleDescription: 'Manage store operations.',
      moduleCount: 2,
      permissionCount: 4,
      modulePreview: ['Outlets', 'Sales'],
    ),
    RoleOption(id: 'role-2', name: 'Cashier', code: 'CASHIER'),
  ],
  outlets: [
    UserOutletOption(
      id: 'outlet-1',
      name: 'Main Outlet',
      code: 'MAIN',
      status: 'ACTIVE',
    ),
  ],
  tills: [
    UserTillOption(
      id: 'till-1',
      outletId: 'outlet-1',
      name: 'Till 01',
      code: 'T01',
      status: 'ACTIVE',
    ),
  ],
  permissionGroups: [
    PermissionGroup(
      groupName: 'Reporting',
      permissions: [
        PermissionItem(
          id: 'perm-1',
          code: 'tenant.reports.view',
          actionType: 'view',
          name: 'View Reports',
        ),
      ],
    ),
  ],
  supportedStatuses: ['INVITED', 'ACTIVE', 'INACTIVE'],
  supportedOutletAccessScopes: [
    'ALL_OUTLETS',
    'SELECTED_OUTLETS',
    'NO_OUTLET_ACCESS',
  ],
  supportedTillAccessScopes: [
    'ALL_ACCESSIBLE_TILLS',
    'SELECTED_TILLS',
    'NO_TILL_ACCESS',
  ],
  capabilities: TenantUserCreateCapabilities(
    supportsInvitedUserCreation: true,
    supportsDirectActiveCreation: true,
    supportsUserPermissionOverrides: true,
    supportsAllOutletAccess: true,
    supportsNoOutletAccess: true,
    supportsExplicitTillAccess: true,
    supportsDefaultOutlet: true,
    supportsDefaultTill: true,
    supportsTemporaryPassword: true,
  ),
  permissionCatalogVersion: 'catalog-v1',
);

TenantAdminAccessChecker _checker() {
  return TenantAdminAccessChecker(
    const TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Coffee Corner Ltd',
      userId: 'user-test',
      userDisplayName: 'Sarah Ahmed',
      roleNames: ['Owner'],
      roles: [TenantAdminRoleScope(roleId: 'role-1', roleName: 'Owner')],
      outletScope: [
        TenantAdminOutletScope(
          outletId: 'outlet-1',
          outletName: 'Main Outlet',
          isDefault: true,
        ),
      ],
      featureEntitlements: [
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.staffManagement,
          featureName: TenantAdminFeatureCodes.staffManagement,
          enabled: true,
        ),
      ],
      permissions: [
        TenantAdminPermission(
          permissionCode: TenantAdminPermissionCodes.tenantUsersCreate,
          permissionName: TenantAdminPermissionCodes.tenantUsersCreate,
        ),
        TenantAdminPermission(
          permissionCode: TenantAdminPermissionCodes.tenantUsersInvite,
          permissionName: TenantAdminPermissionCodes.tenantUsersInvite,
        ),
        TenantAdminPermission(
          permissionCode:
              TenantAdminPermissionCodes.tenantUsersPermissionOverride,
          permissionName:
              TenantAdminPermissionCodes.tenantUsersPermissionOverride,
        ),
      ],
      runtimeFlags: [
        TenantAdminRuntimeFlag(
          featureCode: TenantAdminFeatureCodes.staffManagement,
          enabled: true,
        ),
      ],
    ),
  );
}
