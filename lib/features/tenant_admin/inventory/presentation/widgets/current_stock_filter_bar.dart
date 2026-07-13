import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/constants/inventory_api_paths.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../providers/inventory_providers.dart';

class CurrentStockFilterBar extends ConsumerWidget {
  const CurrentStockFilterBar({
    super.key,
    required this.outlets,
    required this.isMobile,
    required this.activeFilterCount,
    required this.onClearFilters,
  });

  final List<AccessibleOutletOption> outlets;
  final bool isMobile;
  final int activeFilterCount;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TenantAdminSearchField(
            hint: 'Search product, SKU, barcode, or batch',
            onChanged: (value) {
              ref.read(currentStockSearchProvider.notifier).state = value;
              ref.read(currentStockPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openFilterSheet(context, ref),
                  icon: const Icon(Icons.filter_list),
                  label: Text(
                    activeFilterCount == 0
                        ? 'Filters'
                        : 'Filters ($activeFilterCount)',
                  ),
                ),
              ),
              if (activeFilterCount > 0) ...[
                const SizedBox(width: TenantAdminSpacing.md),
                TenantAdminSecondaryButton(
                  label: 'Clear',
                  onPressed: onClearFilters,
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TenantAdminSearchField(
          hint: 'Search product, SKU, barcode, or batch',
          onChanged: (value) {
            ref.read(currentStockSearchProvider.notifier).state = value;
            ref.read(currentStockPageProvider.notifier).state = 1;
          },
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final useSingleColumn = constraints.maxWidth < 900;

            if (useSingleColumn) {
              return Column(
                children: [
                  _OutletFilter(outlets: outlets),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _StockStatusFilter(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _ExpiryStatusFilter(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _OutletFilter(outlets: outlets)),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(child: _StockStatusFilter()),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(child: _ExpiryStatusFilter()),
              ],
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Batch number',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref.read(currentStockBatchFilterProvider.notifier).state =
                      value;
                  ref.read(currentStockPageProvider.notifier).state = 1;
                },
              ),
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: TenantAdminSpacing.md),
              TenantAdminSecondaryButton(
                label: 'Clear filters',
                onPressed: onClearFilters,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _openFilterSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: TenantAdminSpacing.lg,
            right: TenantAdminSpacing.lg,
            top: TenantAdminSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + TenantAdminSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Stock filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              _OutletFilter(outlets: outlets),
              const SizedBox(height: TenantAdminSpacing.md),
              _StockStatusFilter(),
              const SizedBox(height: TenantAdminSpacing.md),
              _ExpiryStatusFilter(),
              const SizedBox(height: TenantAdminSpacing.md),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Batch number',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  ref.read(currentStockBatchFilterProvider.notifier).state =
                      value;
                  ref.read(currentStockPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              TenantAdminPrimaryButton(
                label: 'Apply filters',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutletFilter extends ConsumerWidget {
  const _OutletFilter({required this.outlets});

  final List<AccessibleOutletOption> outlets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(currentStockOutletFilterProvider);

    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Outlet',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All outlets'),
        ),
        ...outlets.map(
          (outlet) => DropdownMenuItem<String?>(
            value: outlet.id,
            child: Text(outlet.name),
          ),
        ),
      ],
      onChanged: (value) {
        ref.read(currentStockOutletFilterProvider.notifier).state = value;
        ref.read(currentStockPageProvider.notifier).state = 1;
        ref.invalidate(currentStockSummaryProvider);
      },
    );
  }
}

class _StockStatusFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(currentStockStatusFilterProvider);

    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Stock status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('All statuses')),
        DropdownMenuItem(
          value: InventoryStockStatusFilter.inStock,
          child: Text('In stock'),
        ),
        DropdownMenuItem(
          value: InventoryStockStatusFilter.lowStock,
          child: Text('Low stock'),
        ),
        DropdownMenuItem(
          value: InventoryStockStatusFilter.outOfStock,
          child: Text('Out of stock'),
        ),
      ],
      onChanged: (value) {
        ref.read(currentStockStatusFilterProvider.notifier).state = value;
        ref.read(currentStockPageProvider.notifier).state = 1;
      },
    );
  }
}

class _ExpiryStatusFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(currentStockExpiryFilterProvider);

    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Expiry status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('All expiry')),
        DropdownMenuItem(
          value: InventoryExpiryStatusFilter.expiring,
          child: Text('Expiring soon'),
        ),
        DropdownMenuItem(
          value: InventoryExpiryStatusFilter.expired,
          child: Text('Expired'),
        ),
      ],
      onChanged: (value) {
        ref.read(currentStockExpiryFilterProvider.notifier).state = value;
        ref.read(currentStockPageProvider.notifier).state = 1;
      },
    );
  }
}

int currentStockActiveFilterCount(WidgetRef ref) {
  final query = ref.watch(currentStockQueryProvider);
  var count = 0;

  if (query.outletId != null && query.outletId!.isNotEmpty) count++;
  if (query.search != null && query.search!.trim().isNotEmpty) count++;
  if (query.stockStatus != null && query.stockStatus!.isNotEmpty) count++;
  if (query.expiryStatus != null && query.expiryStatus!.isNotEmpty) count++;
  if (query.batchNumber != null && query.batchNumber!.trim().isNotEmpty) count++;

  return count;
}
