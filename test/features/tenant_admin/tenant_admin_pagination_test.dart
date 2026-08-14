import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/current_stock/providers/current_stock_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/outlet_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_pagination.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('TenantAdminPaginationBar', () {
    testWidgets('shows five-record ranges and page numbers', (tester) async {
      final changedPages = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantAdminPaginationBar(
              currentPage: 1,
              pageSize: TenantAdminContentTokens.defaultListPageSize,
              totalCount: 23,
              itemLabel: 'users',
              onPageChanged: changedPages.add,
            ),
          ),
        ),
      );

      expect(find.text('Showing 1–5 of 23 users'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      expect(changedPages, [2]);
    });

    testWidgets('wraps controls on compact widths without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 220));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: TenantAdminPaginationBar(
                currentPage: 3,
                pageSize: TenantAdminContentTokens.defaultListPageSize,
                totalCount: 100,
                itemLabel: 'records',
                onPageChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Showing 11–15 of 100 records'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tenant Admin management list defaults', () {
    test('request five records per page by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(userPageSizeProvider),
        TenantAdminContentTokens.defaultListPageSize,
      );
      expect(
        container.read(outletPageSizeProvider),
        TenantAdminContentTokens.defaultListPageSize,
      );
      expect(
        container.read(tillPageSizeProvider),
        TenantAdminContentTokens.defaultListPageSize,
      );
      expect(
        container.read(currentStockPageSizeProvider),
        TenantAdminContentTokens.defaultListPageSize,
      );
      expect(
        container.read(productListFilterProvider).pageSize,
        TenantAdminContentTokens.defaultListPageSize,
      );
    });
  });
}
