import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_dashboard_filters.dart';
import 'product_dashboard_providers.dart';
import 'product_dashboard_visibility.dart';

class ProductDashboardHeader extends ConsumerWidget {
  const ProductDashboardHeader({
    super.key,
    required this.visibility,
    this.lastUpdatedAt,
    this.isRefreshing = false,
    this.onRefresh,
    this.compact = false,
  });

  final ProductDashboardVisibility visibility;
  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final VoidCallback? onRefresh;
  final bool compact;

  static const subtitle =
      'Monitor product availability, stock health, inventory value and stock movement.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final access = accessState.valueOrNull;
    final showAddProduct = access?.canCreateProduct() ?? false;

    final controls = <Widget>[
      if (lastUpdatedAt != null)
        Text(
          'Last updated ${_formatLastUpdated(lastUpdatedAt!)}',
          style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
        ),
      if (onRefresh != null)
        IconButton(
          onPressed: isRefreshing ? null : onRefresh,
          tooltip: 'Refresh dashboard',
          icon: isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      if (showAddProduct)
        FilledButton.icon(
          onPressed: () => context.go('/tenant-admin/products/add'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Product'),
        ),
    ];

    if (visibility.showDateFilter || visibility.showOutletFilter) {
      controls.insert(
        0,
        ProductDashboardFilters(visibility: visibility, expanded: !compact),
      );
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visibility.showTitle)
            Text(
              'Product Dashboard',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
          if (visibility.showSubtitle) ...[
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              subtitle,
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.md),
          ...controls.map(
            (widget) => Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
              child: widget,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (visibility.showTitle)
                    Text(
                      'Product Dashboard',
                      style: TenantAdminTextStyles.sectionTitle(context),
                    ),
                  if (visibility.showSubtitle) ...[
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      subtitle,
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ],
                ],
              ),
            ),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: controls,
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
      ],
    );
  }

  String _formatLastUpdated(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.day}/${local.month}/${local.year} at $hour:$minute $period';
  }
}

void invalidateProductDashboard(WidgetRef ref) {
  ref.invalidate(productDashboardProvider);
}
