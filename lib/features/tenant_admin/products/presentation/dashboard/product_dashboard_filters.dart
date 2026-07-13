import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_dashboard_date_filter.dart';
import 'product_dashboard_outlet_filter.dart';
import 'product_dashboard_providers.dart';
import 'product_dashboard_visibility.dart';

class ProductDashboardFilters extends ConsumerWidget {
  const ProductDashboardFilters({
    super.key,
    required this.visibility,
    this.expanded = true,
  });

  final ProductDashboardVisibility visibility;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visibility.showDateFilter && !visibility.showOutletFilter) {
      return const SizedBox.shrink();
    }

    final filter = ref.watch(productDashboardFilterProvider);
    final children = <Widget>[];

    if (visibility.showDateFilter) {
      children.add(
        expanded
            ? Expanded(
                child: ProductDashboardDateFilter(
                  label: filter.dateLabel,
                  onSelected: (preset) {
                    ref.read(productDashboardFilterProvider.notifier).state =
                        filter.copyWith(preset: preset);
                  },
                  onCustomRange: () => _pickCustomRange(context, ref, filter),
                ),
              )
            : ProductDashboardDateFilter(
                label: filter.dateLabel,
                onSelected: (preset) {
                  ref.read(productDashboardFilterProvider.notifier).state =
                      filter.copyWith(preset: preset);
                },
                onCustomRange: () => _pickCustomRange(context, ref, filter),
              ),
      );
    }

    if (visibility.showOutletFilter) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: TenantAdminSpacing.sm));
      }

      children.add(
        expanded
            ? Expanded(
                child: ProductDashboardOutletFilter(
                  selectedOutletId: filter.outletId,
                  onChanged: (outletId) {
                    ref.read(productDashboardFilterProvider.notifier).state =
                        outletId == null
                            ? filter.copyWith(clearOutletId: true)
                            : filter.copyWith(outletId: outletId);
                  },
                ),
              )
            : ProductDashboardOutletFilter(
                selectedOutletId: filter.outletId,
                onChanged: (outletId) {
                  ref.read(productDashboardFilterProvider.notifier).state =
                      outletId == null
                          ? filter.copyWith(clearOutletId: true)
                          : filter.copyWith(outletId: outletId);
                },
              ),
      );
    }

    if (expanded) {
      return Row(children: children);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: TenantAdminSpacing.sm),
          children[index],
        ],
      ],
    );
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    WidgetRef ref,
    ProductDashboardFilter filter,
  ) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: filter.customFrom ?? filter.dateFrom,
        end: filter.customTo ?? filter.dateTo,
      ),
    );

    if (range == null || !context.mounted) {
      return;
    }

    if (range.end.isBefore(range.start)) {
      return;
    }

    ref.read(productDashboardFilterProvider.notifier).state = filter.copyWith(
      preset: ProductDashboardDatePreset.custom,
      customFrom: range.start,
      customTo: range.end,
    );
  }
}
