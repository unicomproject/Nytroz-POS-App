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
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/screens/add_edit_user_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/screens/user_list_screen.dart';

void main() {
  group('User list screen', () {
    testWidgets('shows unauthorized state when tenant.users.view is missing',
        (tester) async {
      await _pumpUserList(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(find.text('No access to Users'), findsOneWidget);
      expect(find.text('Sarah Ahmed'), findsNothing);
    });

    testWidgets('AddUserButton_Hidden_WhenCreateAndInvitePermissionsMissing',
        (tester) async {
      await _pumpUserList(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
        width: 1200,
      );

      expect(find.text('Add New User'), findsNothing);
      expect(find.text('Sarah Ahmed'), findsOneWidget);
    });

    testWidgets('AddUserButton_Visible_WhenUserCreatePermissionExists',
        (tester) async {
      await _pumpUserList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tenantUsersView,
          TenantAdminPermissionCodes.tenantUsersCreate,
        ],
        features: [TenantAdminFeatureCodes.staffManagement],
        width: 1200,
      );

      expect(find.text('Add New User'), findsOneWidget);
    });

    testWidgets('UsersList_ShowsUserRow_WhenUsersViewPermissionExists',
        (tester) async {
      await _pumpUserList(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
        width: 1200,
      );

      expect(find.text('Sarah Ahmed'), findsOneWidget);
      expect(find.text('sarah@coffeecorner.com'), findsOneWidget);
    });

    testWidgets('search advertises server-supported phone search',
        (tester) async {
      await _pumpUserList(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
        width: 1200,
      );

      expect(find.text('Search users by name, email or phone...'), findsOneWidget);
      expect(find.text('Till Access'), findsNothing);
      expect(find.text('Reset PIN'), findsNothing);
    });
  });

  group('Add/Edit user screen', () {
    testWidgets(
        'CreateUser_DoesNotRenderForm_WhenCreateAndInvitePermissionMissing',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDioProvider.overrideWithValue(Dio()),
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => _checker(
                permissions: [TenantAdminPermissionCodes.tenantUsersView],
                features: [TenantAdminFeatureCodes.staffManagement],
              ),
            ),
          ],
          child: const MaterialApp(home: AddEditUserScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No access'), findsWidgets);
      expect(find.text('Full Name'), findsNothing);
    });
  });
}

Future<void> _pumpUserList(
  WidgetTester tester, {
  required List<String> permissions,
  required List<String> features,
  double width = 800,
  double height = 900,
}) async {
  final accessChecker = _checker(permissions: permissions, features: features);

  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => accessChecker,
        ),
        userListProvider.overrideWith(
          (ref) async => const TenantUserListResult(
            items: [
              TenantUser(
                id: 'user-1',
                fullName: 'Sarah Ahmed',
                email: 'sarah@coffeecorner.com',
                roleName: 'Store Manager',
                outletName: 'High Street Store',
                status: 'ACTIVE',
              ),
            ],
            page: 1,
            pageSize: 10,
            totalCount: 1,
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: const UserListScreen(),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

TenantAdminAccessChecker _checker({
  required List<String> permissions,
  required List<String> features,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Coffee Corner Ltd',
      userId: 'user-test',
      userDisplayName: 'Sarah Ahmed',
      roleNames: const ['Owner'],
      roles: const [
        TenantAdminRoleScope(roleId: 'role-1', roleName: 'Owner'),
      ],
      outletScope: const [
        TenantAdminOutletScope(
          outletId: 'outlet-1',
          outletName: 'High Street Store',
          isDefault: true,
        ),
      ],
      featureEntitlements: [
        for (final featureCode in features)
          TenantAdminFeatureEntitlement(
            featureCode: featureCode,
            featureName: featureCode,
            enabled: true,
          ),
      ],
      permissions: [
        for (final permissionCode in permissions)
          TenantAdminPermission(
            permissionCode: permissionCode,
            permissionName: permissionCode,
          ),
      ],
      runtimeFlags: [
        for (final featureCode in features)
          TenantAdminRuntimeFlag(featureCode: featureCode, enabled: true),
      ],
    ),
  );
}
