import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_dashboard_providers.dart';

class ProductDashboardOutletFilter extends ConsumerWidget {
  const ProductDashboardOutletFilter({
    super.key,
    required this.selectedOutletId,
    required this.onChanged,
  });

  final String? selectedOutletId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletsState = ref.watch(productDashboardOutletsProvider);

    return outletsState.when(
      loading: () => const _FilterChip(
        label: 'All outlets',
        icon: Icons.store_outlined,
      ),
      error: (_, __) => _FilterChip(
        label: 'All outlets',
        icon: Icons.store_outlined,
        onTap: () => onChanged(null),
      ),
      data: (outlets) {
        final label = selectedOutletId == null
            ? 'All outlets'
            : outlets
                    .where((outlet) => outlet.id == selectedOutletId)
                    .map((outlet) => outlet.name)
                    .firstOrNull ??
                'All outlets';

        return PopupMenuButton<String?>(
          onSelected: onChanged,
          itemBuilder: (context) => [
            const PopupMenuItem<String?>(
              value: null,
              child: Text('All outlets'),
            ),
            for (final outlet in outlets)
              PopupMenuItem<String?>(
                value: outlet.id,
                child: Text(outlet.name),
              ),
          ],
          child: _FilterChip(label: label, icon: Icons.store_outlined),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap ?? () {},
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }

    return iterator.current;
  }
}
