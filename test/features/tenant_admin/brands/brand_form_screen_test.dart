import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/entities/brand.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/entities/brand_list_query.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/repositories/brand_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/providers/brand_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/screens/brand_form_screen.dart';

void main() {
  testWidgets('add mode renders approved empty content without Brand Preview',
      (tester) async {
    final repository = _FakeBrandRepository();
    await _pumpForm(tester, repository: repository);

    expect(find.text('Add Brand'), findsWidgets);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Brand Management'), findsOneWidget);
    expect(find.text('Brand Preview'), findsNothing);
    expect(_text(tester, const Key('brand-name-field')), isEmpty);
    expect(_text(tester, const Key('brand-code-field')), isEmpty);
    expect(_text(tester, const Key('brand-sort-order-field')), '0');
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Back to List'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save Brand'), findsOneWidget);
  });

  testWidgets(
      'edit loads by id, prefills once, and submits expected row version',
      (tester) async {
    final repository = _FakeBrandRepository(
      detail: const Brand(
        id: 'brand-a',
        code: 'NIKE',
        name: 'Nike',
        description: 'Shoes',
        sortOrder: 4,
        status: 'INACTIVE',
        logoUrl: 'https://example.test/nike.png',
        rowVersion: 7,
      ),
    );
    await _pumpForm(tester,
        repository: repository, brandId: 'brand-a', settle: false);
    expect(find.byKey(const Key('brand-edit-loading')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(repository.loadedIds, ['brand-a']);
    expect(_text(tester, const Key('brand-name-field')), 'Nike');
    expect(_text(tester, const Key('brand-code-field')), 'NIKE');
    expect(_text(tester, const Key('brand-sort-order-field')), '4');
    expect(find.byKey(const Key('brand-logo-preview')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('brand-name-field')), 'Nike Updated');
    await _tapVisible(tester, find.byKey(const Key('save-brand-button')));
    await tester.pumpAndSettle();

    expect(repository.updateCount, 1);
    expect(repository.lastInput?.expectedRowVersion, 7);
    expect(repository.uploadCount, 0);
  });

  testWidgets('validation rejects blank, overlong, and invalid sort order',
      (tester) async {
    final repository = _FakeBrandRepository();
    await _pumpForm(tester, repository: repository);
    await tester.enterText(find.byKey(const Key('brand-name-field')), ' ');
    await tester.enterText(
        find.byKey(const Key('brand-code-field')), List.filled(81, 'C').join());
    await tester.enterText(
        find.byKey(const Key('brand-sort-order-field')), '-1');
    await _tapVisible(tester, find.byKey(const Key('save-brand-button')));
    await tester.pump();

    expect(find.text('Brand Name is required.'), findsOneWidget);
    expect(repository.createCount, 0);
    expect(find.text('Enter a whole number of 0 or greater.'), findsOneWidget);
  });

  testWidgets(
      'create plus logo failure retries logo only with existing Brand id',
      (tester) async {
    final repository = _FakeBrandRepository()..failUpload = true;
    await _pumpForm(
      tester,
      repository: repository,
      picker: () async =>
          SelectedBrandLogo(Uint8List.fromList([1, 2, 3]), 'logo.png'),
    );
    await tester.enterText(find.byKey(const Key('brand-name-field')), 'Nike');
    await tester.enterText(find.byKey(const Key('brand-code-field')), 'NIKE');
    await _tapVisible(tester, find.text('Upload Logo'));
    await tester.pump();
    await _tapVisible(tester, find.byKey(const Key('save-brand-button')));
    await tester.pumpAndSettle();

    expect(repository.createCount, 1);
    expect(repository.uploadIds, ['created-brand']);
    expect(find.textContaining('Brand created successfully'), findsOneWidget);
    expect(find.text('Retry Logo'), findsOneWidget);

    repository.failUpload = false;
    await _tapVisible(tester, find.text('Retry Logo'));
    await tester.pumpAndSettle();
    expect(repository.createCount, 1);
    expect(repository.uploadIds, ['created-brand', 'created-brand']);
  });

  testWidgets('form has no horizontal overflow at 1024x768 and 1280x800',
      (tester) async {
    for (final size in [
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await _pumpForm(tester, repository: _FakeBrandRepository());
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('brand-logo-preview')), findsOneWidget);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextFormField>(find.byKey(key)).controller!.text;

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  final pageScroll = find.byType(SingleChildScrollView).first;
  for (var attempt = 0; attempt < 4; attempt++) {
    final center = tester.getCenter(finder);
    final logicalHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    if (center.dy >= 0 && center.dy <= logicalHeight) break;
    await tester.drag(
        pageScroll, Offset(0, center.dy > logicalHeight ? -350 : 350));
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required _FakeBrandRepository repository,
  String? brandId,
  Future<SelectedBrandLogo?> Function()? picker,
  bool settle = true,
}) async {
  final router = GoRouter(
    initialLocation: '/form',
    routes: [
      GoRoute(
          path: '/form',
          builder: (_, __) =>
              Scaffold(body: BrandFormScreen(brandId: brandId))),
      GoRoute(
          path: '/tenant-admin/brands',
          builder: (_, __) => const Scaffold(body: Text('Brand list target'))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        brandRepositoryProvider.overrideWithValue(repository),
        if (picker != null) brandLogoPickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

class _FakeBrandRepository implements BrandRepository {
  _FakeBrandRepository({this.detail});
  final Brand? detail;
  final List<String> loadedIds = [];
  final List<String> uploadIds = [];
  int createCount = 0;
  int updateCount = 0;
  int uploadCount = 0;
  bool failUpload = false;
  BrandUpsertInput? lastInput;

  Brand get _saved => Brand(
        id: detail?.id ?? 'created-brand',
        code: lastInput?.code ?? 'NIKE',
        name: lastInput?.name ?? 'Nike',
        status: lastInput?.status ?? 'ACTIVE',
        rowVersion: (lastInput?.expectedRowVersion ?? 0) + 1,
      );

  @override
  Future<Brand> createBrand(BrandUpsertInput input) async {
    createCount++;
    lastInput = input;
    return _saved;
  }

  @override
  Future<Brand> getBrandById(String id) async {
    loadedIds.add(id);
    return detail!;
  }

  @override
  Future<Brand> updateBrand(String id, BrandUpsertInput input) async {
    updateCount++;
    lastInput = input;
    return _saved;
  }

  @override
  Future<Brand> uploadBrandLogo(
      String id, Uint8List bytes, String fileName) async {
    uploadCount++;
    uploadIds.add(id);
    if (failUpload) throw Exception('storage unavailable');
    return _saved;
  }

  @override
  Future<void> deleteBrand(String id) async {}

  @override
  Future<BrandListResult> listBrands({required BrandListQuery query}) async =>
      const BrandListResult(
          items: [], pageNumber: 1, pageSize: 5, totalCount: 0);
}
