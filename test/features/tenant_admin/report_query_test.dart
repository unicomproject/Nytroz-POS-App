import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/data/constants/report_api_paths.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/domain/entities/report_query.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/presentation/providers/report_providers.dart';

void main() {
  group('ReportQuery', () {
    test('serializes supported values without tenant ownership authority', () {
      final query = ReportQuery(
        from: DateTime(2026, 7, 1),
        to: DateTime(2026, 7, 15),
        outletId: 'outlet-1',
        search: ' INV-100 ',
        section: ReportSections.transactions,
        page: 2,
        pageSize: 50,
        sortBy: 'completedAt',
        sortDirection: 'desc',
      );

      final parameters = query.toQueryParameters();

      expect(parameters['from'], '2026-07-01');
      expect(parameters['to'], '2026-07-15');
      expect(parameters['outletId'], 'outlet-1');
      expect(parameters['search'], 'INV-100');
      expect(parameters['page'], 2);
      expect(parameters['pageSize'], 50);
      expect(parameters.containsKey('tenantId'), isFalse);
    });

    test('validates mandatory dates and supported page sizes', () {
      const missingDates = ReportQuery(section: ReportSections.transactions);
      const invalidPageSize = ReportQuery(
        section: ReportSections.transactions,
        pageSize: 10,
      );

      expect(
        missingDates.validate(datesRequired: true),
        'From date and to date are required.',
      );
      expect(
        invalidPageSize.validate(datesRequired: false),
        'Page size must be 25, 50, or 100.',
      );
    });
  });

  group('ReportQueryNotifier', () {
    test('initial query uses the current business month date range', () {
      final container = ProviderContainer(
        overrides: [
          reportBusinessDateProvider.overrideWithValue(DateTime(2026, 7, 15)),
        ],
      );
      addTearDown(container.dispose);

      final query = container.read(reportQueryProvider(ReportScope.dashboard));

      expect(query.from, DateTime(2026, 7));
      expect(query.to, DateTime(2026, 7, 15));
      expect(query.validate(datesRequired: true), isNull);
    });

    test('resets page and clears dependent filters', () {
      final notifier = ReportQueryNotifier(
        const ReportQuery(
          section: ReportSections.products,
          departmentId: 'department-1',
          categoryId: 'category-1',
          subcategoryId: 'subcategory-1',
          page: 4,
        ),
      );

      notifier.setNamedFilter('departmentId', 'department-2');

      expect(notifier.state.departmentId, 'department-2');
      expect(notifier.state.categoryId, isNull);
      expect(notifier.state.subcategoryId, isNull);
      expect(notifier.state.page, 1);
    });
  });
}
