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
  group('AddUserWizardScreen', () {
    testWidgets('renders Step 1 canonical fields', (tester) async {
      await _pumpWizard(tester);

      expect(find.text('Add New User'), findsOneWidget);
      expect(find.text('Basic Information'), findsWidgets);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Employee ID'), findsOneWidget);
      expect(find.text('Staff Code'), findsOneWidget);
      expect(find.text('Auto-generated when user is created'), findsOneWidget);
      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
      expect(find.text('ACTIVE'), findsNothing);
    });

    testWidgets(
        'phone is optional and Step 1 validation blocks missing required fields',
        (tester) async {
      await _pumpWizard(tester);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Full Name is required.'), findsOneWidget);
      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Role is required.'), findsOneWidget);
      expect(find.textContaining('Phone is required'), findsNothing);
    });

    testWidgets('role options load from create-options', (tester) async {
      await _pumpWizard(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Store Manager'), findsWidgets);
      expect(find.text('Cashier'), findsWidgets);
    });

    testWidgets('Step 2 supports all outlets and specific outlets',
        (tester) async {
      await _advanceToAccessSetup(tester);

      expect(find.text('Access Setup'), findsWidgets);
      expect(
        find.text("Configure the user's role, outlet access and permissions."),
        findsOneWidget,
      );
      expect(find.text('Assigned Role'), findsOneWidget);
      expect(find.text('Store Manager'), findsOneWidget);
      expect(
        find.text("Role determines the user's base permissions."),
        findsOneWidget,
      );
      expect(find.text('Outlet Access'), findsOneWidget);
      expect(find.text('All Outlets'), findsOneWidget);
      expect(find.text('Specific Outlets'), findsOneWidget);

      await tester.tap(find.text('Specific Outlets'));
      await tester.pump();

      expect(find.text('Main Outlet'), findsOneWidget);
      expect(find.text('City Outlet'), findsOneWidget);
    });

    testWidgets('Step 2 excludes unresolved access fields', (tester) async {
      await _advanceToAccessSetup(tester);

      expect(find.text('Default Outlet'), findsNothing);
      expect(find.text('Default Till'), findsNothing);
      expect(find.text('Outlet-specific Role Override'), findsNothing);
      expect(find.text('Access Start Date'), findsNothing);
      expect(find.text('Access Notes'), findsNothing);
    });

    testWidgets(
        'permission override is off by default and expands from backend groups',
        (tester) async {
      await _advanceToAccessSetup(tester);

      expect(find.text('Enable permission override'), findsOneWidget);
      expect(find.text('View Reports'), findsNothing);

      await tester.tap(find.text('Enable permission override'));
      await tester.pump();

      expect(find.text('Reporting'), findsOneWidget);
      expect(find.text('View Reports'), findsOneWidget);
      expect(find.text('Manage Products'), findsNothing);
    });

    testWidgets('selected access survives Back and Next', (tester) async {
      await _advanceToAccessSetup(tester);

      await tester.tap(find.text('Specific Outlets'));
      await tester.pump();
      await tester.tap(find.text('Main Outlet'));
      await tester.pump();
      await _tapVisible(tester, find.text('Back'));
      await tester.pump();
      await _tapVisible(tester, find.text('Next'));
      await tester.pump();

      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Main Outlet'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('Step 2 uses connected stepper and desktop action hierarchy',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _advanceToAccessSetup(tester);

        expect(
          find.byKey(const ValueKey('addUserWizardStepperConnector0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('addUserWizardStepperConnector1')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Step 1, Basic Information, completed'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Step 2, Access Setup, current'),
          findsOneWidget,
        );

        final backLeft = tester.getTopLeft(find.text('Back')).dx;
        final cancelLeft = tester.getTopLeft(find.text('Cancel')).dx;
        final nextLeft = tester.getTopLeft(find.text('Next')).dx;

        expect(backLeft, lessThan(nextLeft));
        expect(cancelLeft, lessThan(nextLeft));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Step 2 desktop, tablet and mobile layouts have no overflow',
        (tester) async {
      for (final size in const [
        Size(1600, 900),
        Size(1366, 768),
        Size(1024, 768),
        Size(390, 900),
      ]) {
        await _advanceToAccessSetup(
          tester,
          width: size.width,
          height: size.height,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Step 3 review shows invited security message', (tester) async {
      await _advanceToReview(tester, invited: true);

      expect(find.text('Security & Review'), findsWidgets);
      expect(find.text('INVITED'), findsOneWidget);
      expect(
        find.text(
          'The user will receive a secure invitation email to set up their password.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('token'), findsNothing);
      expect(find.textContaining('password:'), findsNothing);
    });

    testWidgets('Step 3 review shows inactive security message',
        (tester) async {
      await _advanceToReview(tester);

      expect(find.text('INACTIVE'), findsOneWidget);
      expect(
        find.text(
          'This account will be created inactive and cannot sign in until activated through the approved lifecycle.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('dirty Cancel shows discard confirmation', (tester) async {
      await _pumpWizard(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Kavin Perera');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard user setup?'), findsOneWidget);
      expect(
          find.text('Your entered information will be lost.'), findsOneWidget);
      expect(find.text('Continue editing'), findsOneWidget);
      expect(find.text('Discard and return to Users'), findsOneWidget);
    });

    testWidgets('desktop layout has no overflow', (tester) async {
      await _pumpWizard(tester, width: 1600, height: 900);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile layout has no overflow', (tester) async {
      await _pumpWizard(tester, width: 390, height: 900);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _advanceToAccessSetup(
  WidgetTester tester, {
  double width = 1200,
  double height = 900,
}) async {
  await _pumpWizard(tester, width: width, height: height);
  await tester.enterText(find.byType(TextFormField).at(0), 'Kavin Perera');
  await tester.enterText(find.byType(TextFormField).at(2), 'kavin@oneverz.com');
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Store Manager').last);
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text('Next'));
  await tester.pump();
}

Future<void> _advanceToReview(
  WidgetTester tester, {
  bool invited = false,
}) async {
  await _advanceToAccessSetup(tester);
  if (invited) {
    await _tapVisible(tester, find.text('Back'));
    await tester.pump();
    await tester.tap(find.text('Invited'));
    await tester.pump();
    await _tapVisible(tester, find.text('Next'));
    await tester.pump();
  }
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
  double width = 1200,
  double height = 900,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(Dio()),
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => _checker(),
        ),
        userCreateOptionsProvider.overrideWith(
          (ref) async => _createOptions,
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: AddUserWizardScreen())),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

const _createOptions = TenantUserCreateOptions(
  roles: [
    RoleOption(id: 'role-1', name: 'Store Manager', code: 'MGR'),
    RoleOption(id: 'role-2', name: 'Cashier', code: 'CASHIER'),
  ],
  outlets: [
    UserOutletOption(
      id: 'outlet-1',
      name: 'Main Outlet',
      code: 'MAIN',
      status: 'ACTIVE',
    ),
    UserOutletOption(
      id: 'outlet-2',
      name: 'City Outlet',
      code: 'CITY',
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
          actionType: 'View',
          description: 'View Reports',
        ),
      ],
    ),
  ],
);

TenantAdminAccessChecker _checker() {
  return TenantAdminAccessChecker(
    const TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Coffee Corner Ltd',
      userId: 'user-test',
      userDisplayName: 'Sarah Ahmed',
      roleNames: ['Owner'],
      roles: [
        TenantAdminRoleScope(roleId: 'role-1', roleName: 'Owner'),
      ],
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
