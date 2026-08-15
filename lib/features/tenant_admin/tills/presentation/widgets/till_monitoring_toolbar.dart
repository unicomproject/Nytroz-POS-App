import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../providers/till_providers.dart';
import '../utils/till_list_filters.dart';

class TillMonitoringToolbar extends ConsumerStatefulWidget {
  const TillMonitoringToolbar({
    super.key,
    required this.visibility,
  });

  final TillListVisibility visibility;

  @override
  ConsumerState<TillMonitoringToolbar> createState() =>
      _TillMonitoringToolbarState();
}

class _TillMonitoringToolbarState extends ConsumerState<TillMonitoringToolbar> {
  Timer? _debounce;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(tillSearchProvider));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(tillPageProvider.notifier).state = 1;
      ref.read(tillSearchProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusFilter = ref.watch(tillStatusFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.visibility.showSearch)
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tills by name, outlet or cashier',
              prefixIcon:
                  const Icon(Icons.search, color: TenantAdminColors.mutedText),
              filled: true,
              fillColor: TenantAdminColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: TenantAdminColors.posHomeAccentOrange,
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: 14,
              ),
            ),
          ),
        if (widget.visibility.showFilters) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              _buildFilterChip(TillStatusFilter.all, statusFilter),
              _buildFilterChip(TillStatusFilter.online, statusFilter),
              _buildFilterChip(TillStatusFilter.offline, statusFilter),
              _buildFilterChip(TillStatusFilter.needsAttention, statusFilter),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(
    TillStatusFilter filter,
    TillStatusFilter currentFilter,
  ) {
    final isSelected = filter == currentFilter;
    final dotColor = switch (filter) {
      TillStatusFilter.online => TenantAdminColors.success,
      TillStatusFilter.offline => TenantAdminColors.danger,
      TillStatusFilter.needsAttention => Colors.amber.shade700,
      TillStatusFilter.all || TillStatusFilter.inactive => null,
    };

    return InkWell(
      onTap: () {
        ref.read(tillPageProvider.notifier).state = 1;
        ref.read(tillStatusFilterProvider.notifier).state = filter;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.10)
              : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? TenantAdminColors.posHomeAccentOrange
                : TenantAdminColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
            ],
            Text(
              filter.label,
              style: TextStyle(
                color: isSelected
                    ? TenantAdminColors.posHomeAccentOrange
                    : TenantAdminColors.bodyText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
