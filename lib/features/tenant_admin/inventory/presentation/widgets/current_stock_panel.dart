import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/inventory.dart';
import '../config/inventory_api_capabilities.dart';
import '../providers/inventory_providers.dart';
import 'current_stock_list_view.dart';

class CurrentStockFiltersSheet extends ConsumerWidget {
  const CurrentStockFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockOnly = ref.watch(inventoryLowStockFilterProvider);
    final search = ref.watch(inventorySearchProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: TenantAdminSpacing.lg,
        right: TenantAdminSpacing.lg,
        top: TenantAdminSpacing.lg,
        bottom: MediaQuery.paddingOf(context).bottom + TenantAdminSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          TenantAdminSearchField(
            hint: 'Search by product or variant...',
            value: search,
            onChanged: (value) {
              ref.read(inventorySearchProvider.notifier).state = value;
              ref.read(inventoryPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Low stock only'),
            value: lowStockOnly,
            onChanged: (value) {
              ref.read(inventoryLowStockFilterProvider.notifier).state = value;
              ref.read(inventoryPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TenantAdminSecondaryButton(
                label: 'Clear',
                onPressed: () {
                  ref.read(inventorySearchProvider.notifier).state = '';
                  ref.read(inventoryLowStockFilterProvider.notifier).state =
                      false;
                  ref.read(inventoryPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              TenantAdminPrimaryButton(
                label: 'Apply',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrentStockPanel extends ConsumerWidget {
  const CurrentStockPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.isMobile,
    this.locations = const [],
    this.locationsLoading = false,
    this.onView,
  });

  final InventoryBalanceListResult result;
  final CurrentStockVisibility visibility;
  final bool isMobile;
  final List<InventoryLocation> locations;
  final bool locationsLoading;
  final ValueChanged<InventoryBalanceRow>? onView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocationId = ref.watch(inventorySelectedLocationProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08071A33),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x04071A33),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationFilter(
                        locations: locations,
                        locationsLoading: locationsLoading,
                        selectedLocationId: selectedLocationId,
                        onChanged: (value) => ref
                            .read(inventorySelectedLocationProvider.notifier)
                            .state = value,
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                      _HeaderActions(visibility: visibility),
                    ],
                  )
                : Row(
                    children: [
                      _LocationFilter(
                        locations: locations,
                        locationsLoading: locationsLoading,
                        selectedLocationId: selectedLocationId,
                        onChanged: (value) => ref
                            .read(inventorySelectedLocationProvider.notifier)
                            .state = value,
                      ),
                      const Spacer(),
                      _HeaderActions(visibility: visibility),
                    ],
                  ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (result.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              child: TenantAdminEmptyState(
                title: 'No stock records',
                message: 'No inventory balances found for the selected filters.',
                icon: Icons.inventory_2_outlined,
              ),
            )
          else
            CurrentStockListView(
              items: result.items,
              visibility: visibility,
              isMobile: isMobile,
              onView: onView,
            ),
          if (result.totalCount > 0)
            _PaginationFooter(
              page: result.page,
              pageSize: result.pageSize,
              totalCount: result.totalCount,
              onPageChanged: (nextPage) =>
                  ref.read(inventoryPageProvider.notifier).state = nextPage,
            ),
        ],
      ),
    );
  }
}

class _LocationFilter extends StatelessWidget {
  const _LocationFilter({
    required this.locations,
    required this.locationsLoading,
    required this.selectedLocationId,
    required this.onChanged,
  });

  final List<InventoryLocation> locations;
  final bool locationsLoading;
  final String? selectedLocationId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!InventoryApiCapabilities.listLocations) {
      return const Text(
        'All locations',
        style: TextStyle(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (locationsLoading) {
      return const SizedBox(
        width: 220,
        child: LinearProgressIndicator(),
      );
    }

    if (locations.isEmpty) {
      return const Text(
        'No locations available',
        style: TextStyle(color: TenantAdminColors.mutedText),
      );
    }

    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<String>(
        value: locations.any((item) => item.id == selectedLocationId)
            ? selectedLocationId
            : null,
        decoration: const InputDecoration(
          labelText: 'Outlet / Location',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: locations
            .map(
              (location) => DropdownMenuItem(
                value: location.id,
                child: Text(location.name),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.visibility});

  final CurrentStockVisibility visibility;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        if (visibility.showFilters)
          TenantAdminSecondaryButton(
            label: 'Filters',
            icon: Icons.filter_list,
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => const CurrentStockFiltersSheet(),
              );
            },
          ),
        if (visibility.showExport)
          TenantAdminSecondaryButton(
            label: 'Export',
            icon: Icons.download_outlined,
            onPressed: null,
          ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages =
        pageSize <= 0 ? 1 : (totalCount / pageSize).ceil().clamp(1, 9999);
    final rangeStart = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final rangeEnd = (page * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount items',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '$page / $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed:
                page < totalPages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
