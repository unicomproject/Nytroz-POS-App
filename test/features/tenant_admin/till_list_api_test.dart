import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/application/usecases/create_till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/application/usecases/get_tills.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/utils/till_api_errors.dart';

void main() {
  group('Till list provider', () {
    test('TillList_DoesNotCallApi_WhenNoTillViewPermission', () async {
      final repository = _TrackingTillRepository();

      final container = ProviderContainer(
        overrides: [
          tenantAdminAccessCheckerProvider.overrideWith(
            (ref) async => _checker(
              permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
              features: [TenantAdminFeatureCodes.dashboard],
            ),
          ),
          tillRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(tillListProvider.future);

      expect(result, isNull);
      expect(repository.getTillsCalled, isFalse);
    });

    test('TillList_CallsApi_WhenTillViewPermissionExists', () async {
      final repository = _TrackingTillRepository();

      final container = ProviderContainer(
        overrides: [
          tenantAdminAccessCheckerProvider.overrideWith(
            (ref) async => _checker(
              permissions: [TenantAdminPermissionCodes.tillView],
              features: [TenantAdminFeatureCodes.tillManagement],
            ),
          ),
          tillRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(tillListProvider.future);

      expect(repository.getTillsCalled, isTrue);
      expect(result, isNotNull);
      expect(result!.items, isNotEmpty);
    });
  });

  group('Create till', () {
    test('CreateTill_CallsPostApi_WhenTillCreatePermissionExists', () async {
      final repository = _TrackingTillRepository();

      final created = await CreateTill(repository).call(
        const TillFormData(
          name: 'Front Counter Till',
          code: 'TILL-001',
          outletId: 'outlet-1',
          status: 'active',
        ),
      );

      expect(repository.createTillCalled, isTrue);
      expect(created.id, 'till-created');
    });

    test('CreateTill_ShowsForbiddenMessage_On403', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/tenant-admin/tills'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/tenant-admin/tills'),
          statusCode: 403,
          data: {
            'message': 'Access denied.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        tillSubmitErrorMessage(error, const {}),
        'Access denied.',
      );
    });

    test('CreateTill_ShowsDuplicateMessage_On409', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/tenant-admin/tills'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/tenant-admin/tills'),
          statusCode: 409,
          data: {
            'message': 'Till code already exists.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        tillSubmitErrorMessage(error, const {}),
        'Till code already exists.',
      );
    });

    test('CreateTill_RefreshesList_On201', () async {
      final repository = _TrackingTillRepository();

      final container = ProviderContainer(
        overrides: [
          tenantAdminAccessCheckerProvider.overrideWith(
            (ref) async => _checker(
              permissions: [
                TenantAdminPermissionCodes.tillView,
                TenantAdminPermissionCodes.tillCreate,
              ],
              features: [TenantAdminFeatureCodes.tillManagement],
            ),
          ),
          tillRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tillListProvider.future);
      expect(repository.getTillsCallCount, 1);

      await container.read(createTillProvider).call(
            const TillFormData(
              name: 'New Till',
              code: 'TILL-002',
              outletId: 'outlet-1',
              status: 'active',
            ),
          );

      container.invalidate(tillListProvider);
      await container.read(tillListProvider.future);

      expect(repository.createTillCalled, isTrue);
      expect(repository.getTillsCallCount, 2);
    });
  });
}

class _TrackingTillRepository implements TillRepository {
  var getTillsCalled = false;
  var getTillsCallCount = 0;
  var createTillCalled = false;

  @override
  Future<CreatedTill> createTill(TillFormData form) async {
    createTillCalled = true;
    return const CreatedTill(
      id: 'till-created',
      outletId: 'outlet-1',
      name: 'Front Counter Till',
      code: 'TILL-001',
      status: 'active',
    );
  }

  @override
  Future<TillListResult> getTills({required TillListQuery query}) async {
    getTillsCalled = true;
    getTillsCallCount++;
    return const TillListResult(
      summary: TillListSummary(
        totalTills: 1,
        onlineCount: 1,
        offlineCount: 0,
        needsAttentionCount: 0,
      ),
      items: [
        Till(
          id: 'till-1',
          outletId: 'outlet-1',
          outletName: 'High Street Store',
          name: 'Front Counter Till',
          code: 'TILL-001',
          status: 'active',
          operationalStatus: 'online',
        ),
      ],
      page: 1,
      pageSize: 10,
      totalCount: 1,
    );
  }
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
