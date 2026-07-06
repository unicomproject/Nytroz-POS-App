import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_search_field.dart';

class ReturnSearchBar extends StatelessWidget {
  const ReturnSearchBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onSearch,
    required this.onToggleFilters,
    this.showFilters = false,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;
  final VoidCallback onToggleFilters;
  final bool showFilters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            constraints.maxWidth < TenantAdminBreakpoints.mobile;

        final filterButton = OutlinedButton.icon(
          onPressed: onToggleFilters,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: showFilters
                ? TenantAdminColors.primary.withValues(alpha: 0.08)
                : TenantAdminColors.surface,
            side: BorderSide(
              color: showFilters
                  ? TenantAdminColors.primary
                  : TenantAdminColors.border,
            ),
          ),
          icon: const Icon(Icons.filter_list_rounded, size: 18),
          label: const Text('Filters'),
        );

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TenantAdminSearchField(
                hint: 'Search by invoice no, mobile number, customer name',
                value: query,
                onChanged: onQueryChanged,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              filterButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TenantAdminSearchField(
                hint: 'Search by invoice no, mobile number, customer name',
                value: query,
                onChanged: onQueryChanged,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            filterButton,
          ],
        );
      },
    );
  }
}
