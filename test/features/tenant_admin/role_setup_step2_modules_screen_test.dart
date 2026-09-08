import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/permission_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/role_setup.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/presentation/providers/role_setup_wizard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/presentation/screens/role_setup_step2_modules_screen.dart';

void main() {
  testWidgets('renders feature-wise permission modules returned by catalog',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roleSetupWizardProvider.overrideWith(
            () => _FeatureModuleWizardController(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RoleSetupStep2ModulesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Outlets'), findsOneWidget);
    expect(find.text('Tills'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Core Commerce'), findsNothing);
    expect(find.textContaining('grouped by business area'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FeatureModuleWizardController extends RoleSetupWizardController {
  @override
      RoleSetupWizardState build() => const RoleSetupWizardState(
        currentStep: 2,
        availableRoles: [],
        selectedRole: RoleSetupOption(
          id: 'cashier',
          code: 'CASHIER',
          name: 'Cashier',
          isActive: true,
          isSystem: true,
          permissionCount: 3,
          userCount: 1,
          updatedAt: null,
        ),
        selectedModules: {'outlets', 'tills', 'users'},
        selectedPermissionCodes: {},
        assignments: [],
        isLoading: false,
        isSaving: false,
        catalog: PermissionCatalog(
          modules: [
            PermissionCatalogModule(
              id: 'outlets',
              code: 'outlets',
              name: 'Outlets',
              description: 'Manage outlet information and operations.',
              scope: 'TENANT',
              sortOrder: 2,
              isActive: true,
              features: [
                PermissionCatalogFeature(
                  id: 'outlet-management',
                  code: 'outlet_management',
                  name: 'Outlet Management',
                  sortOrder: 1,
                  isActive: true,
                  permissions: [
                    PermissionCatalogPermission(
                      id: 'outlets-view',
                      code: 'tenant.outlets.view',
                      name: 'View outlets',
                      scope: 'TENANT',
                      sortOrder: 1,
                      isActive: true,
                      source: 'TENANT',
                    ),
                  ],
                ),
              ],
            ),
            PermissionCatalogModule(
              id: 'tills',
              code: 'tills',
              name: 'Tills',
              description: 'Till configuration and monitoring.',
              scope: 'TENANT',
              sortOrder: 3,
              isActive: true,
              features: [
                PermissionCatalogFeature(
                  id: 'till-management',
                  code: 'till_management',
                  name: 'Till Management',
                  sortOrder: 1,
                  isActive: true,
                  permissions: [
                    PermissionCatalogPermission(
                      id: 'tills-view',
                      code: 'tenant.tills.view',
                      name: 'View tills',
                      scope: 'TENANT',
                      sortOrder: 1,
                      isActive: true,
                      source: 'TENANT',
                    ),
                  ],
                ),
              ],
            ),
            PermissionCatalogModule(
              id: 'users',
              code: 'users',
              name: 'Users',
              description: 'Manage user access.',
              scope: 'TENANT',
              sortOrder: 4,
              isActive: true,
              features: [
                PermissionCatalogFeature(
                  id: 'user-accounts',
                  code: 'user_accounts',
                  name: 'User Accounts',
                  sortOrder: 1,
                  isActive: true,
                  permissions: [
                    PermissionCatalogPermission(
                      id: 'users-view',
                      code: 'tenant.users.view',
                      name: 'View users',
                      scope: 'TENANT',
                      sortOrder: 1,
                      isActive: true,
                      source: 'TENANT',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}
