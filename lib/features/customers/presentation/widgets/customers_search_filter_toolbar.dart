import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_search_field.dart';
import '../providers/customers_provider.dart';

class CustomersSearchFilterToolbar extends StatelessWidget {
  const CustomersSearchFilterToolbar({
    super.key,
    required this.query,
    required this.statusFilter,
    required this.sourceFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSourceChanged,
    required this.onClear,
  });

  final String query;
  final CustomerStatusFilter statusFilter;
  final CustomerSourceFilter sourceFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusChanged;
  final ValueChanged<CustomerSourceFilter> onSourceChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wrap = constraints.maxWidth < 900;
        final search = Expanded(
          child: TenantAdminSearchField(
            hint: 'Search by name, phone, email, or customer ID...',
            value: query,
            onChanged: onSearchChanged,
          ),
        );

        final filters = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusFilter(
              value: statusFilter,
              onChanged: onStatusChanged,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            _SourceFilter(
              value: sourceFilter,
              onChanged: onSourceChanged,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Clear'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TenantAdminColors.bodyText,
                side: const BorderSide(color: TenantAdminColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.md,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
          ],
        );

        if (wrap) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TenantAdminSearchField(
                hint: 'Search by name, phone, email, or customer ID...',
                value: query,
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: filters,
              ),
            ],
          );
        }

        return Row(
          children: [
            search,
            const SizedBox(width: TenantAdminSpacing.md),
            filters,
          ],
        );
      },
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.value,
    required this.onChanged,
  });

  final CustomerStatusFilter value;
  final ValueChanged<CustomerStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<CustomerStatusFilter>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        decoration: _filterDecoration('Status'),
        items: const [
          DropdownMenuItem(
            value: CustomerStatusFilter.all,
            child: Text('All'),
          ),
          DropdownMenuItem(
            value: CustomerStatusFilter.active,
            child: Text('Active'),
          ),
          DropdownMenuItem(
            value: CustomerStatusFilter.inactive,
            child: Text('Inactive'),
          ),
        ],
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}

class _SourceFilter extends StatelessWidget {
  const _SourceFilter({
    required this.value,
    required this.onChanged,
  });

  final CustomerSourceFilter value;
  final ValueChanged<CustomerSourceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<CustomerSourceFilter>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        decoration: _filterDecoration('Source'),
        items: const [
          DropdownMenuItem(
            value: CustomerSourceFilter.all,
            child: Text('All'),
          ),
          DropdownMenuItem(
            value: CustomerSourceFilter.pos,
            child: Text('POS'),
          ),
          DropdownMenuItem(
            value: CustomerSourceFilter.manual,
            child: Text('Manual'),
          ),
          DropdownMenuItem(
            value: CustomerSourceFilter.ecommerce,
            child: Text('E-commerce'),
          ),
          DropdownMenuItem(
            value: CustomerSourceFilter.import,
            child: Text('Import'),
          ),
        ],
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}

InputDecoration _filterDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: TenantAdminColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: TenantAdminSpacing.md,
      vertical: 10,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
  );
}
