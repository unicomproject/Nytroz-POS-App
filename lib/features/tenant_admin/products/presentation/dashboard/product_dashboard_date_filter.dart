import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_dashboard_providers.dart';

class ProductDashboardDateFilter extends StatelessWidget {
  const ProductDashboardDateFilter({
    super.key,
    required this.label,
    required this.onSelected,
    required this.onCustomRange,
  });

  final String label;
  final ValueChanged<ProductDashboardDatePreset> onSelected;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductDashboardDatePreset>(
      onSelected: (preset) {
        if (preset == ProductDashboardDatePreset.custom) {
          onCustomRange();
          return;
        }

        onSelected(preset);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ProductDashboardDatePreset.today,
          child: Text('Today'),
        ),
        PopupMenuItem(
          value: ProductDashboardDatePreset.yesterday,
          child: Text('Yesterday'),
        ),
        PopupMenuItem(
          value: ProductDashboardDatePreset.last7,
          child: Text('Last 7 Days'),
        ),
        PopupMenuItem(
          value: ProductDashboardDatePreset.last30,
          child: Text('Last 30 Days'),
        ),
        PopupMenuItem(
          value: ProductDashboardDatePreset.custom,
          child: Text('Custom Range'),
        ),
      ],
      child: _FilterChip(label: label, icon: Icons.calendar_today),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: TenantAdminColors.bodyText,
        backgroundColor: TenantAdminColors.surface,
        side: const BorderSide(color: TenantAdminColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
