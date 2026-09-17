import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/data/mappers/brand_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/data/models/brand_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/entities/brand.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/entities/brand_list_query.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/repositories/brand_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/providers/brand_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/providers/brand_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/screens/brand_list_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/widgets/brand_details_side_panel.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/widgets/brand_table.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_footer_navigation.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

void main() {
  group('BrandMapper', () {
    test('maps logo, sortOrder and productCount from dto', () {
      final entity = BrandMapper.toEntity(
        const BrandDto(
          id: '1',
          brandCode: 'ACME',
          brandName: 'Acme',
          status: 'ACTIVE',
          description: 'Desc',
          logoUrl: 'https://cdn.example/logo.png',
          logoMediaAssetId: 'media-1',
          sortOrder: 5,
          productCount: 12,
        ),
      );

      expect(entity.code, 'ACME');
      expect(entity.logoUrl, 'https://cdn.example/logo.png');
      expect(entity.sortOrder, 5);
      expect(entity.productCount, 12);
      expect(entity.hasLogo, isTrue);
    });

    test('maps upsert sortOrder into request dto', () {
      final dto = BrandMapper.toRequestDto(
        const BrandUpsertInput(
          code: 'ACME',
          name: 'Acme',
          status: 'ACTIVE',
          sortOrder: 7,
        ),
      );

      expect(dto.sortOrder, 7);
      expect(dto.toJson()['sortOrder'], 7);
    });
  });

  group('Brand list/detail state', () {
    test('defaults Brand pagination to five rows', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(brandPageSizeProvider), 5);
      expect(container.read(brandListQueryProvider).pageSize, 5);
    });

    test('starts without a selection and does not request detail', () {
      final repository = _FakeBrandRepository();
      final container = ProviderContainer(overrides: [
        brandRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);

      expect(container.read(selectedBrandIdProvider), isNull);
      expect(repository.detailRequests, isEmpty);
    });

    testWidgets('detail is read-only and close clears its host',
        (tester) async {
      final repository = _FakeBrandRepository();
      var closed = false;
      await tester.pumpWidget(ProviderScope(
        overrides: [brandRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: BrandDetailsSidePanel(
              brandId: 'samsung',
              onClose: () => closed = true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(repository.detailRequests, ['samsung']);
      for (final text in [
        'Brand Name',
        'Samsung',
        'Code',
        'SAMSUNG',
        'Description',
        'Consumer electronics',
        'Sort Order',
        '4',
        'Brand Image',
        'Status',
        'Active'
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Save Brand'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Change Image'), findsNothing);

      await tester.tap(find.byTooltip('Close brand details'));
      expect(closed, isTrue);
    });

    testWidgets('screen is full width initially then shows and closes details',
        (tester) async {
      final repository = _FakeBrandRepository();
      const result = BrandListResult(
        items: [_FakeBrandRepository.brand],
        pageNumber: 1,
        pageSize: 10,
        totalCount: 1,
      );
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          brandRepositoryProvider.overrideWithValue(repository),
          brandListVisibilityProvider.overrideWithValue(
            const AsyncData(_visibility),
          ),
          brandListScreenProvider.overrideWith((ref) async => result),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1440, 900)),
            child: Scaffold(body: BrandListScreen()),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand-full-width-list')), findsOneWidget);
      expect(find.byKey(const Key('brand-shared-workspace')), findsOneWidget);
      expect(find.byKey(const Key('brand-workspace-divider')), findsNothing);
      expect(find.byKey(const Key('brand-details-region')), findsNothing);
      expect(repository.detailRequests, isEmpty);
      final addButton = tester.widget<ElevatedButton>(find.descendant(
        of: find.byKey(const Key('add-brand-button')),
        matching: find.byType(ElevatedButton),
      ));
      expect(
        addButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        TenantAdminColors.posHomeOrangeEnd,
      );
      for (final crumb in ['Product', 'Brand', 'Brand Management']) {
        expect(find.text(crumb), findsOneWidget);
      }

      await tester.tap(find.text('Samsung').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('brand-selected-layout')), findsOneWidget);
      expect(find.byKey(const Key('brand-shared-workspace')), findsOneWidget);
      expect(find.byKey(const Key('brand-workspace-divider')), findsOneWidget);
      expect(find.byKey(const Key('brand-details-region')), findsWidgets);
      expect(repository.detailRequests, ['samsung']);

      await tester.tap(find.byTooltip('Close brand details').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('brand-full-width-list')), findsOneWidget);
      expect(find.byKey(const Key('brand-workspace-divider')), findsNothing);
      expect(find.byKey(const Key('brand-details-region')), findsNothing);
    });

    testWidgets('1024px desktop selection renders inline details',
        (tester) async {
      final repository = _FakeBrandRepository();
      const result = BrandListResult(
        items: [_FakeBrandRepository.brand, _FakeBrandRepository.unilever],
        pageNumber: 1,
        pageSize: 10,
        totalCount: 2,
      );
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer(
        overrides: [
          brandRepositoryProvider.overrideWithValue(repository),
          brandListVisibilityProvider.overrideWithValue(
            const AsyncData(_visibility),
          ),
          brandListScreenProvider.overrideWith((ref) async => result),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1024, 768)),
            child: Scaffold(
              body: SizedBox(width: 780, child: BrandListScreen()),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand-full-width-list')), findsOneWidget);
      expect(find.byKey(const Key('brand-shared-workspace')), findsOneWidget);
      expect(find.byKey(const Key('brand-workspace-divider')), findsNothing);
      expect(find.byKey(const Key('brand-details-region')), findsNothing);

      await tester.tap(find.text('Samsung').last);
      await tester.pumpAndSettle();

      expect(repository.detailRequests, ['samsung']);
      expect(find.byKey(const Key('brand-selected-layout')), findsOneWidget);
      expect(find.byKey(const Key('brand-workspace-divider')), findsOneWidget);
      expect(find.byKey(const Key('brand-details-region')), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('brand-data-table')), findsOneWidget);
      expect(find.byTooltip('Edit brand'), findsWidgets);
      expect(find.byTooltip('Delete brand'), findsWidgets);
      expect(container.read(selectedBrandIdProvider), 'samsung');

      final listRect = tester.getRect(
        find.byKey(const Key('brand-reduced-width-list')),
      );
      final detailsRect = tester.getRect(
        find.byKey(const Key('brand-details-region')),
      );
      final workspaceRect = tester.getRect(
        find.byKey(const Key('brand-shared-workspace')),
      );
      expect(listRect.right, lessThanOrEqualTo(detailsRect.left));
      expect(detailsRect.right, lessThanOrEqualTo(workspaceRect.right));
      expect(listRect.width, lessThan(workspaceRect.width));
      expect(detailsRect.width, greaterThan(0));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Unilever').last);
      await tester.pumpAndSettle();
      expect(repository.detailRequests, ['samsung', 'unilever']);
      expect(find.text('UNILEVER'), findsWidgets);
      expect(find.byKey(const Key('brand-details-region')), findsOneWidget);
      expect(container.read(selectedBrandIdProvider), 'unilever');

      await tester.tap(find.byTooltip('Close brand details'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('brand-full-width-list')), findsOneWidget);
      expect(find.byKey(const Key('brand-details-region')), findsNothing);
      expect(container.read(selectedBrandIdProvider), isNull);
    });

    testWidgets('table has exactly the approved seven centered columns',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1600, 900)),
            child: Scaffold(
              body: BrandTable(
                result: BrandListResult(
                  items: [_FakeBrandRepository.brand],
                  pageNumber: 1,
                  pageSize: 10,
                  totalCount: 57,
                ),
                canEdit: true,
                canDelete: true,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ));

      for (final header in [
        'Brand Logo',
        'Brand Name',
        'Code',
        'Product Count',
        'Status',
        'Updated On',
        'Actions'
      ]) {
        expect(find.text(header), findsOneWidget);
      }
      expect(find.text('Sort Order'), findsNothing);
      expect(find.text('Showing 1 to 10 of 57 brands'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      final tableWidth = tester.getSize(find.byType(DataTable)).width;
      final hostWidth =
          tester.getSize(find.byKey(const Key('brand-data-table'))).width;
      expect(tableWidth, greaterThanOrEqualTo(hostWidth - 2));
      final activePage = tester.widget<Container>(
        find.byKey(const Key('brand-active-page')),
      );
      expect(
        (activePage.decoration as BoxDecoration).color,
        TenantAdminColors.posHomeOrangeEnd,
      );
    });

    testWidgets('pagination offers tablet-first page sizes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1180, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1180, 820)),
            child: Scaffold(
              body: BrandTable(
                result: const BrandListResult(
                  items: [_FakeBrandRepository.brand],
                  pageNumber: 1,
                  pageSize: 5,
                  totalCount: 12,
                ),
                canEdit: true,
                canDelete: true,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Showing 1 to 5 of 12 brands'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsWidgets);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    for (final viewport in const [
      Size(1024, 768),
      Size(1280, 720),
      Size(1440, 900),
    ]) {
      testWidgets(
          '${viewport.width.toInt()}x${viewport.height.toInt()} selected geometry stays bounded',
          (tester) async {
        final repository = _FakeBrandRepository();
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(ProviderScope(
          overrides: [
            brandRepositoryProvider.overrideWithValue(repository),
            brandListVisibilityProvider.overrideWithValue(
              const AsyncData(_visibility),
            ),
            brandListScreenProvider
                .overrideWith((ref) async => const BrandListResult(
                      items: _pageOneBrands,
                      pageNumber: 1,
                      pageSize: 5,
                      totalCount: 7,
                    )),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: viewport),
              child: const Scaffold(body: BrandListScreen()),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Samsung').last);
        await tester.pumpAndSettle();

        final workspace = tester.getRect(
          find.byKey(const Key('brand-shared-workspace')),
        );
        final list = tester.getRect(
          find.byKey(const Key('brand-reduced-width-list')),
        );
        final divider = tester.getRect(
          find.byKey(const Key('brand-workspace-divider')),
        );
        final details = tester.getRect(
          find.byKey(const Key('brand-details-region')),
        );
        final add = tester.getRect(find.byKey(const Key('add-brand-button')));
        final table = tester.getRect(find.byKey(const Key('brand-data-table')));
        final pagination =
            tester.getRect(find.byKey(const Key('brand-pagination')));

        expect(list.right, lessThanOrEqualTo(divider.left));
        expect(divider.right, lessThanOrEqualTo(details.left));
        expect(details.right, lessThanOrEqualTo(workspace.right));
        expect(add.left, greaterThanOrEqualTo(list.left));
        expect(add.right, lessThanOrEqualTo(list.right));
        expect(table.left, greaterThanOrEqualTo(list.left));
        expect(table.right, lessThanOrEqualTo(list.right));
        expect(pagination.left, greaterThanOrEqualTo(list.left));
        expect(pagination.right, lessThanOrEqualTo(list.right));
        expect(
          find.descendant(
            of: find.byKey(const Key('brand-data-table')),
            matching: find.byTooltip(
              'Edit brand',
            ),
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('seven records paginate as five then two', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Future<void> pumpPage(List<Brand> brands, int page) => tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: const MediaQueryData(size: Size(1280, 720)),
                  child: Scaffold(
                    body: BrandTable(
                      result: BrandListResult(
                        items: brands,
                        pageNumber: page,
                        pageSize: 5,
                        totalCount: 7,
                      ),
                      canEdit: true,
                      canDelete: true,
                      onSelect: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );

      await pumpPage(_pageOneBrands, 1);
      for (final brand in _pageOneBrands) {
        expect(find.text(brand.name), findsOneWidget);
      }
      expect(find.text(_pageTwoBrands.first.name), findsNothing);
      expect(find.text('Showing 1 to 5 of 7 brands'), findsOneWidget);

      await pumpPage(_pageTwoBrands, 2);
      for (final brand in _pageTwoBrands) {
        expect(find.text(brand.name), findsOneWidget);
      }
      expect(find.text(_pageOneBrands.first.name), findsNothing);
      expect(find.text('Showing 6 to 7 of 7 brands'), findsOneWidget);
    });
  });

  group('Tenant Admin footer path helper', () {
    test('does not mark brand or product catalog routes as settings', () {
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/brands'), isFalse);
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/products'), isFalse);
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/dashboard'), isFalse);
      expect(isTenantAdminSettingsAreaPath('/pos/home'), isFalse);
    });
  });
}

const _visibility = BrandListVisibility(
  showPage: true,
  showTitle: true,
  showSubtitle: true,
  showSearch: true,
  showAddBrand: true,
  showList: true,
  showEditBrand: true,
  showDeleteBrand: true,
);

const _pageOneBrands = [
  _FakeBrandRepository.brand,
  _FakeBrandRepository.unilever,
  Brand(id: '3', code: 'NESTLE', name: 'Nestle', status: 'ACTIVE'),
  Brand(id: '4', code: 'SONY', name: 'Sony', status: 'ACTIVE'),
  Brand(id: '5', code: 'LG', name: 'LG Electronics', status: 'ACTIVE'),
];

const _pageTwoBrands = [
  Brand(id: '6', code: 'APPLE', name: 'Apple', status: 'ACTIVE'),
  Brand(id: '7', code: 'NIKE', name: 'Nike', status: 'ACTIVE'),
];

class _FakeBrandRepository implements BrandRepository {
  static const brand = Brand(
    id: 'samsung',
    code: 'SAMSUNG',
    name: 'Samsung',
    status: 'ACTIVE',
    description: 'Consumer electronics',
    sortOrder: 4,
    productCount: 9,
  );
  static const unilever = Brand(
    id: 'unilever',
    code: 'UNILEVER',
    name: 'Unilever',
    status: 'ACTIVE',
    description: 'Consumer goods',
    sortOrder: 5,
    productCount: 3,
  );

  final List<String> detailRequests = [];

  @override
  Future<Brand> getBrandById(String id) async {
    detailRequests.add(id);
    return id == unilever.id ? unilever : brand;
  }

  @override
  Future<BrandListResult> listBrands({required BrandListQuery query}) async =>
      BrandListResult(
          items: const [brand],
          pageNumber: query.pageNumber,
          pageSize: query.pageSize,
          totalCount: 1);

  @override
  Future<Brand> createBrand(BrandUpsertInput input) =>
      throw UnimplementedError();
  @override
  Future<void> deleteBrand(String id) => throw UnimplementedError();
  @override
  Future<Brand> updateBrand(String id, BrandUpsertInput input) =>
      throw UnimplementedError();
  @override
  Future<Brand> uploadBrandLogo(String id, Uint8List bytes, String fileName) =>
      throw UnimplementedError();
}
