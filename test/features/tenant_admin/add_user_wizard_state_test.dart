import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/application/usecases/create_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/tenant_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/user_profile_image_upload.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/repositories/tenant_user_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/add_user_wizard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_providers.dart';

void main() {
  group('AddUserWizardController canonical five-step flow', () {
    test('Step 1 validates identity only and Step 2 validates role', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      expect(controller.next(), isFalse);
      var state = container.read(addUserWizardControllerProvider);
      expect(state.fieldErrors['fullName'], isNotNull);
      expect(state.fieldErrors['email'], isNotNull);
      expect(state.fieldErrors['roleId'], isNull);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com');
      expect(controller.next(), isTrue);
      state = container.read(addUserWizardControllerProvider);
      expect(state.currentStep, AddUserWizardStep.assignRole);
      expect(controller.next(), isFalse);
      expect(
        container.read(addUserWizardControllerProvider).fieldErrors['roleId'],
        isNotNull,
      );
    });

    test('navigates through all five canonical steps', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..next()
        ..setRoleId('role-1');

      expect(controller.next(), isTrue);
      expect(
        container.read(addUserWizardControllerProvider).currentStep,
        AddUserWizardStep.configurePermissions,
      );
      expect(controller.next(), isTrue);
      expect(
        container.read(addUserWizardControllerProvider).currentStep,
        AddUserWizardStep.accessScope,
      );
      expect(controller.next(), isTrue);
      expect(
        container.read(addUserWizardControllerProvider).currentStep,
        AddUserWizardStep.securityReview,
      );
    });

    test('active account requires a strong matching password', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setAccountStatus(AddUserAccountStatus.active);

      expect(controller.next(), isFalse);
      expect(
        container.read(addUserWizardControllerProvider).fieldErrors['password'],
        isNotNull,
      );

      controller
        ..setPassword('SecurePass123')
        ..setConfirmPassword('SecurePass123');

      expect(controller.next(), isTrue);
      controller.setRoleId('role-1');
      final form = container.read(addUserWizardControllerProvider).toFormData();
      expect(form.status, 'ACTIVE');
      expect(form.password, 'SecurePass123');
      expect(form.confirmPassword, 'SecurePass123');
      expect(form.sendInviteEmail, isFalse);
    });

    test('selected outlet scope requires an outlet and prunes stale tills', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);
      const tills = [
        UserTillOption(
          id: 'till-1',
          outletId: 'outlet-1',
          name: 'Till 1',
          code: 'T1',
          status: 'ACTIVE',
        ),
      ];

      controller
        ..setOutletAccessMode(AddUserOutletAccessMode.selectedOutlets)
        ..setTillAccessMode(AddUserTillAccessMode.selectedTills)
        ..toggleOutlet('outlet-1', true, tills: tills)
        ..toggleTill('till-1', true)
        ..setDefaultOutlet('outlet-1')
        ..setDefaultTill('till-1')
        ..toggleOutlet('outlet-1', false, tills: tills);

      final state = container.read(addUserWizardControllerProvider);
      expect(state.selectedTillIds, isEmpty);
      expect(state.defaultOutletId, isNull);
      expect(state.defaultTillId, isNull);
    });

    test('atomic form carries exact outlet, till and catalog contract', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..syncCreateOptions(_options)
        ..setFullName(' Kavin Perera ')
        ..setEmail(' KAVIN@oneverz.com ')
        ..setRoleId('role-1')
        ..setOutletAccessMode(AddUserOutletAccessMode.selectedOutlets)
        ..toggleOutlet('outlet-1', true, tills: _options.tills)
        ..setDefaultOutlet('outlet-1')
        ..setTillAccessMode(AddUserTillAccessMode.selectedTills)
        ..toggleTill('till-1', true)
        ..setDefaultTill('till-1')
        ..setPermissionOverrideEnabled(
          true,
          inheritedPermissionIds: const ['perm-1'],
        );

      final form = container.read(addUserWizardControllerProvider).toFormData();
      expect(form.fullName, 'Kavin Perera');
      expect(form.email, 'kavin@oneverz.com');
      expect(form.outletAccessScope, 'SELECTED_OUTLETS');
      expect(form.outletIds, ['outlet-1']);
      expect(form.defaultOutletId, 'outlet-1');
      expect(form.tillAccessScope, 'SELECTED_TILLS');
      expect(form.tillIds, ['till-1']);
      expect(form.defaultTillId, 'till-1');
      expect(form.permissionCatalogVersion, 'catalog-v1');
      expect(form.overriddenPermissionIds, ['perm-1']);
    });

    test('catalog mismatch returns to permission step', () async {
      final repository = _FakeRepository()
        ..nextError = DioException(
          requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
            statusCode: 409,
            data: const {
              'code': 'user.permission_catalog_mismatch',
              'message': 'Catalog changed',
            },
          ),
        );
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);
      controller
        ..syncCreateOptions(_options)
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1');

      expect(await controller.submit(), isNull);
      expect(
        container.read(addUserWizardControllerProvider).currentStep,
        AddUserWizardStep.configurePermissions,
      );
    });

    test('successful create resets state and uses one idempotency key',
        () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);
      controller
        ..syncCreateOptions(_options)
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1');

      final created = await controller.submit();
      final state = container.read(addUserWizardControllerProvider);
      expect(created?.id, 'user-1');
      expect(repository.idempotencyKeys.single, isNotEmpty);
      expect(state.currentStep, AddUserWizardStep.basicInformation);
      expect(state.isDirty, isFalse);
    });
  });
}

ProviderContainer _container([_FakeRepository? repository]) {
  final fake = repository ?? _FakeRepository();
  return ProviderContainer(
    overrides: [createUserProvider.overrideWithValue(CreateUser(fake))],
  );
}

const _options = TenantUserCreateOptions(
  roles: [RoleOption(id: 'role-1', name: 'Cashier', code: 'CASHIER')],
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
      name: 'Till 1',
      code: 'T1',
      status: 'ACTIVE',
    ),
  ],
  permissionGroups: [
    PermissionGroup(
      groupName: 'Sales',
      permissions: [
        PermissionItem(
          id: 'perm-1',
          code: 'sales.create',
          actionType: 'create',
        ),
      ],
    ),
  ],
  supportedStatuses: ['INVITED', 'INACTIVE'],
  permissionCatalogVersion: 'catalog-v1',
);

class _FakeRepository implements TenantUserRepository {
  final idempotencyKeys = <String>[];
  DioException? nextError;

  @override
  Future<TenantUserDetail> createUser(
    UserFormData form, {
    String? idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey ?? '');
    if (nextError case final error?) throw error;
    return TenantUserDetail(
      id: 'user-1',
      fullName: form.fullName,
      email: form.email,
      roleId: form.roleId,
      roleName: 'Cashier',
      outlets: const [],
      status: form.status ?? 'INACTIVE',
      permissionOverrideEnabled: form.permissionOverrideEnabled,
      overriddenPermissionIds: form.overriddenPermissionIds,
    );
  }

  @override
  Future<void> deleteUser(String id) async {}

  @override
  Future<void> deleteStagedProfileImage(String mediaAssetId) async {}

  @override
  Future<UserProfileImageUpload> uploadProfileImage(
    UserProfileImageUploadInput input, {
    void Function(int sent, int total)? onProgress,
  }) =>
      throw UnimplementedError();

  @override
  Future<TenantUserCreateOptions> getCreateOptions() async => _options;

  @override
  Future<TenantUserDetail> getUserById(String id) => throw UnimplementedError();

  @override
  Future<TenantUserListResult> getUsers({required TenantUserListQuery query}) =>
      throw UnimplementedError();

  @override
  Future<TenantUserDetail> updateUser(String id, UserFormData form) =>
      throw UnimplementedError();
}
