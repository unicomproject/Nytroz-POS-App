import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/application/usecases/create_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/tenant_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/repositories/tenant_user_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/add_user_wizard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_providers.dart';

void main() {
  group('AddUserWizardController', () {
    test('validates Step 1 and does not require phone', () {
      final container = _container();
      addTearDown(container.dispose);

      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      expect(controller.next(), isFalse);
      var state = container.read(addUserWizardControllerProvider);
      expect(state.fieldErrors['fullName'], isNotNull);
      expect(state.fieldErrors['email'], isNotNull);
      expect(state.fieldErrors['roleId'], isNotNull);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1');

      expect(controller.next(), isTrue);
      state = container.read(addUserWizardControllerProvider);
      expect(state.currentStep, AddUserWizardStep.accessSetup);
      expect(state.phone, isEmpty);
    });

    test('maps all outlets to empty outletIds', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1')
        ..next();

      final form = container.read(addUserWizardControllerProvider).toFormData();

      expect(form.outletIds, isEmpty);
    });

    test('requires specific outlet selection', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1')
        ..next()
        ..setOutletAccessMode(AddUserOutletAccessMode.specificOutlets);

      expect(controller.next(), isFalse);
      expect(
        container.read(addUserWizardControllerProvider).fieldErrors['outletIds'],
        'Select at least one outlet.',
      );
    });

    test('does not send stale permission IDs when override is off', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setPermissionOverrideEnabled(true)
        ..togglePermission('perm-1', true)
        ..setPermissionOverrideEnabled(false)
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1');

      final form = container.read(addUserWizardControllerProvider).toFormData();

      expect(form.permissionOverrideEnabled, isFalse);
      expect(form.overriddenPermissionIds, isEmpty);
    });

    test('maps final form data without generated staff code', () {
      final container = _container();
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName(' Kavin Perera ')
        ..setEmail(' kavin@oneverz.com ')
        ..setPhone(' 0771234567 ')
        ..setEmployeeId(' EMP-100 ')
        ..setRoleId('role-1')
        ..setAccountStatus(AddUserAccountStatus.invited)
        ..setProfileMedia(mediaAssetId: 'media-1', fileName: 'profile.png')
        ..next()
        ..setOutletAccessMode(AddUserOutletAccessMode.specificOutlets)
        ..toggleOutlet('outlet-1', true)
        ..setPermissionOverrideEnabled(true)
        ..togglePermission('perm-1', true);

      final form = container.read(addUserWizardControllerProvider).toFormData();

      expect(form.fullName, 'Kavin Perera');
      expect(form.email, 'kavin@oneverz.com');
      expect(form.phone, '0771234567');
      expect(form.employeeId, 'EMP-100');
      expect(form.status, 'INVITED');
      expect(form.profileMediaAssetId, 'media-1');
      expect(form.outletIds, ['outlet-1']);
      expect(form.permissionOverrideEnabled, isTrue);
      expect(form.overriddenPermissionIds, ['perm-1']);
    });

    test('keeps same idempotency key for same failed submission retry',
        () async {
      final repository = _FakeRepository()
        ..nextError = DioException(
          requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
            statusCode: 504,
            data: const {'message': 'Gateway timeout'},
          ),
        );
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1')
        ..next()
        ..next();

      expect(await controller.submit(), isNull);
      final firstKey = repository.idempotencyKeys.single;
      expect(firstKey, isNotEmpty);

      repository.nextError = null;
      final created = await controller.submit();

      expect(created, isNotNull);
      expect(repository.idempotencyKeys, [firstKey, firstKey]);
    });

    test('backend Step 2 field error returns user to access setup', () async {
      final repository = _FakeRepository()
        ..nextError = DioException(
          requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
            statusCode: 400,
            data: const {
              'message': 'Validation failed',
              'details': [
                {'field': 'outletIds', 'message': 'Invalid outlet.'},
              ],
            },
          ),
        );
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1')
        ..next()
        ..next();

      expect(await controller.submit(), isNull);
      final state = container.read(addUserWizardControllerProvider);
      expect(state.currentStep, AddUserWizardStep.accessSetup);
      expect(state.fieldErrors['outletIds'], 'Invalid outlet.');
    });

    test('backend Step 1 field error returns user to basic information',
        () async {
      final repository = _FakeRepository()
        ..nextError = DioException(
          requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/tenant-admin/users'),
            statusCode: 409,
            data: const {
              'message': 'Validation failed',
              'details': [
                {'field': 'email', 'message': 'Email is already in use.'},
              ],
            },
          ),
        );
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1')
        ..next()
        ..next();

      expect(await controller.submit(), isNull);
      final state = container.read(addUserWizardControllerProvider);
      expect(state.currentStep, AddUserWizardStep.basicInformation);
      expect(state.fieldErrors['email'], 'Email is already in use.');
    });

    test('successful create clears wizard state', () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller =
          container.read(addUserWizardControllerProvider.notifier);

      controller
        ..setFullName('Kavin Perera')
        ..setEmail('kavin@oneverz.com')
        ..setRoleId('role-1')
        ..setAccountStatus(AddUserAccountStatus.invited)
        ..setProfileMedia(mediaAssetId: 'media-1', fileName: 'profile.png')
        ..next()
        ..next();

      final created = await controller.submit();
      final state = container.read(addUserWizardControllerProvider);

      expect(created?.id, 'user-1');
      expect(repository.forms.single.profileMediaAssetId, 'media-1');
      expect(repository.idempotencyKeys.single, isNotEmpty);
      expect(state.currentStep, AddUserWizardStep.basicInformation);
      expect(state.fullName, isEmpty);
      expect(state.profileMediaAssetId, isNull);
      expect(state.idempotencyKey, isNull);
      expect(state.isDirty, isFalse);
    });
  });
}

ProviderContainer _container([_FakeRepository? repository]) {
  final fakeRepository = repository ?? _FakeRepository();
  return ProviderContainer(
    overrides: [
      createUserProvider.overrideWithValue(CreateUser(fakeRepository)),
    ],
  );
}

class _FakeRepository implements TenantUserRepository {
  final idempotencyKeys = <String>[];
  final forms = <UserFormData>[];
  DioException? nextError;

  @override
  Future<TenantUserDetail> createUser(
    UserFormData form, {
    String? idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey ?? '');
    forms.add(form);
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }

    return TenantUserDetail(
      id: 'user-1',
      fullName: form.fullName,
      email: form.email,
      roleId: form.roleId,
      roleName: 'Store Manager',
      outlets: const [],
      status: form.status ?? 'INACTIVE',
      permissionOverrideEnabled: form.permissionOverrideEnabled,
      overriddenPermissionIds: form.overriddenPermissionIds,
      staffCode: 'USR-2026-00001',
    );
  }

  @override
  Future<void> deleteUser(String id) async {}

  @override
  Future<TenantUserCreateOptions> getCreateOptions() async {
    return const TenantUserCreateOptions(
      roles: [RoleOption(id: 'role-1', name: 'Store Manager', code: 'MGR')],
      outlets: [],
      permissionGroups: [],
    );
  }

  @override
  Future<TenantUserDetail> getUserById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<TenantUserListResult> getUsers({required TenantUserListQuery query}) {
    throw UnimplementedError();
  }

  @override
  Future<TenantUserDetail> updateUser(String id, UserFormData form) {
    throw UnimplementedError();
  }
}
