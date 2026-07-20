import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnSelectItemsToolbar extends StatelessWidget {
  const ReturnSelectItemsToolbar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.filtersActive,
    required this.onToggleFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool filtersActive;
  final VoidCallback onToggleFilters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final searchField = SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by item name, SKU or barcode',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              filled: true,
              fillColor: TenantAdminColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
            ),
          ),
        );

        final filterButton = SizedBox(
          height: 48,
          width: compact ? double.infinity : 118,
          child: OutlinedButton.icon(
            onPressed: onToggleFilters,
            icon: const Icon(Icons.filter_alt_outlined, size: 20),
            label: Text(filtersActive ? 'All Items' : 'Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TenantAdminColors.bodyText,
              side: BorderSide(
                color: filtersActive
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: TenantAdminSpacing.sm),
              filterButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: TenantAdminSpacing.md),
            filterButton,
          ],
        );
      },
    );
  }
}
