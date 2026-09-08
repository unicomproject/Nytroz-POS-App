import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/application/tax_management_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/data/tax_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/domain/tax_aggregate.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/domain/tax_status.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/domain/tax_treatment.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/presentation/tax_management_page.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';

class _FakeTaxRepo implements TaxRepository {
  @override
  Future<TaxSetupListResult> listTaxSetups(TaxSetupListQuery query) async {
    return TaxSetupListResult(
      items: [
        TaxSetup(
          id: '1',
          name: 'Standard Tax',
          code: 'STD-TAX',
          taxTreatment: TaxTreatment.taxable,
          status: TaxStatus.active,
          currentRate: 18,
          currentRateEffectiveFrom: DateTime(2026, 1, 1),
          nextRate: 20,
          nextRateEffectiveFrom: DateTime(2027, 1, 1),
          productCount: 5,
        ),
        TaxSetup(
          id: '2',
          name: 'Tax Exempt',
          code: 'EXEMPT',
          taxTreatment: TaxTreatment.exempt,
          status: TaxStatus.active,
          currentRate: 0,
          productCount: 0,
        ),
      ],
      pageNumber: 1,
      pageSize: 5,
      totalCount: 2,
    );
  }

  @override
  Future<TaxSetup> getTaxSetup(String id) => throw UnimplementedError();

  @override
  Future<String> createTaxSetup(TaxSetupCreateInput input) =>
      throw UnimplementedError();

  @override
  Future<void> updateTaxSetup(String id, TaxSetupUpdateInput input) =>
      throw UnimplementedError();

  @override
  Future<void> scheduleRate(String id, TaxRateScheduleInput input) =>
      throw UnimplementedError();

  @override
  Future<void> updateScheduledRate(
    String id,
    String rateId,
    TaxRateScheduleInput input,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteScheduledRate(String id, String rateId) =>
      throw UnimplementedError();

  @override
  Future<TaxStatusChangeResult> activateTaxSetup(String id) =>
      throw UnimplementedError();

  @override
  Future<TaxStatusChangeResult> deactivateTaxSetup(
    String id, {
    String? reason,
  }) =>
      throw UnimplementedError();

  @override
  Future<TaxProductUsingListResult> listProductsUsing(
    String id,
    TaxProductsQuery query,
  ) =>
      throw UnimplementedError();
}

TenantAdminAccessChecker _access(Iterable<String> permissionCodes) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-1',
      tenantName: 'SCS-TIX',
      userId: 'user-1',
      userDisplayName: 'Tenant Admin',
      roles: const [],
      roleNames: const ['Tenant Admin'],
      outletScope: const [],
      featureEntitlements: const [],
      permissions: [
        for (final code in permissionCodes)
          TenantAdminPermission(
            permissionCode: code,
            permissionName: code,
          ),
      ],
      runtimeFlags: const [],
    ),
  );
}

void main() {
  testWidgets('Tax Setup list renders canonical columns without Used For',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final access = _access(const [
      'pricing.tax_classes.view',
      'pricing.tax_classes.create',
      'pricing.tax_classes.update',
      'pricing.tax_classes.status.manage',
      'pricing.tax_classes.products.view',
      'pricing.tax_rates.view',
      'pricing.tax_rates.schedule.manage',
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tenantAdminAccessCheckerProvider.overrideWith(
            (ref) async => access,
          ),
          taxRepositoryProvider.overrideWithValue(_FakeTaxRepo()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TaxManagementPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tax Setup'), findsWidgets);
    expect(find.text('Manage tax rates used by your products.'), findsOneWidget);
    expect(find.text('Add Tax Setup'), findsOneWidget);
    expect(find.text('Standard Tax'), findsOneWidget);
    expect(find.text('STD-TAX'), findsOneWidget);
    expect(find.text('18%'), findsOneWidget);
    expect(find.text('Exempt'), findsOneWidget);
    expect(find.textContaining('Used For'), findsNothing);
    expect(find.textContaining('Applies To'), findsNothing);
  });

  testWidgets('permission denied hides list', (tester) async {
    final access = _access(const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tenantAdminAccessCheckerProvider.overrideWith(
            (ref) async => access,
          ),
          taxRepositoryProvider.overrideWithValue(_FakeTaxRepo()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TaxManagementPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('permission'), findsWidgets);
  });
}
