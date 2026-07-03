import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/application/usecases/create_product.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/product_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/utils/product_api_errors.dart';

void main() {
  group('Product list provider', () {
    test('ProductsList_DoesNotCallProductsApi_WhenProductViewPermissionMissing',
        () async {
      final repository = _TrackingProductRepository();

      final container = ProviderContainer(
        overrides: [
          tenantAdminAccessCheckerProvider.overrideWith(
            (ref) async => _checker(
              permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
              features: [TenantAdminFeatureCodes.dashboard],
            ),
          ),
          productRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(productListProvider.future);

      expect(result, isNull);
      expect(repository.getProductsCalled, isFalse);
    });

    test('ProductsList_CallsProductsApi_WhenProductViewPermissionExists',
        () async {
      final repository = _TrackingProductRepository();

      final container = ProviderContainer(
        overrides: [
          tenantAdminAccessCheckerProvider.overrideWith(
            (ref) async => _checker(
              permissions: [TenantAdminPermissionCodes.productView],
              features: [TenantAdminFeatureCodes.productManagement],
            ),
          ),
          productRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(productListProvider.future);

      expect(repository.getProductsCalled, isTrue);
      expect(result, isNotNull);
      expect(result!.items, isNotEmpty);
    });
  });

  group('Create product', () {
    test('CreateProduct_CallsPostApi_WhenProductCreatePermissionExists',
        () async {
      final repository = _TrackingProductRepository();

      final created = await CreateProduct(repository).call(
        const ProductFormData(
          name: 'Coca Cola 500ml',
          sku: 'PRD-0001',
          sellingPrice: 120,
        ),
      );

      expect(repository.createProductCalled, isTrue);
      expect(created.id, 'product-created');
    });

    test('CreateProduct_ShowsForbiddenMessage_On403', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/tenant-admin/products'),
        response: Response(
          requestOptions:
              RequestOptions(path: '/api/v1/tenant-admin/products'),
          statusCode: 403,
          data: const {'message': 'Access denied.'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        productSubmitErrorMessage(error, const {}),
        'Access denied.',
      );
    });

    test('CreateProduct_ShowsDuplicateSkuOrBarcodeMessage_On409', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/tenant-admin/products'),
        response: Response(
          requestOptions:
              RequestOptions(path: '/api/v1/tenant-admin/products'),
          statusCode: 409,
          data: const {
            'message': 'A product with this SKU already exists.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        productSubmitErrorMessage(error, const {}),
        'A product with this SKU already exists.',
      );
    });
  });

  group('Add product access', () {
    test('AddProductRoute_Blocked_WhenProductCreatePermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productView],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(access.canCreateProduct(), isFalse);
      expect(
        AddProductFormVisibility.resolve(access: access).showSaveProduct,
        isFalse,
      );
    });

    test('AddProductRoute_Allows_WhenProductCreatePermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.productView,
          TenantAdminPermissionCodes.productCreate,
        ],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(access.canCreateProduct(), isTrue);
      expect(
        AddProductFormVisibility.resolve(access: access).showSaveProduct,
        isTrue,
      );
    });
  });
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
      userDisplayName: 'Tenant Admin 001',
      roles: const [
        TenantAdminRoleScope(roleId: 'role-owner', roleName: 'Owner'),
      ],
      roleNames: const ['Owner'],
      outletScope: const [],
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

class _TrackingProductRepository implements ProductRepository {
  bool getProductsCalled = false;
  bool createProductCalled = false;

  @override
  Future<ProductListResult> getProducts(ProductListQuery query) async {
    getProductsCalled = true;
    return const ProductListResult(
      summary: ProductListSummary(
        totalProducts: 1,
        activeProducts: 1,
        inactiveProducts: 0,
        productCategories: 1,
      ),
      items: [
        Product(
          id: 'product-1',
          variantId: 'variant-1',
          name: 'Sample Product',
          sku: 'PRD-0001',
          status: 'active',
        ),
      ],
      totalCount: 1,
    );
  }

  @override
  Future<CreatedProduct> createProduct(ProductFormData data) async {
    createProductCalled = true;
    return CreatedProduct(
      id: 'product-created',
      variantId: 'variant-created',
      name: data.name,
      sku: data.sku,
      status: 'draft',
    );
  }

  @override
  Future<void> uploadProductImage({
    required String productId,
    required List<int> bytes,
    required String fileName,
  }) async {}
}
