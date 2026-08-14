import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';

class InventoryHeader extends ConsumerWidget {
  const InventoryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Dashboard',
                  style: TenantAdminTextStyles.pageTitle(context),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Monitor inventory health and take action on priority items.',
                  style: (Theme.of(context).textTheme.bodyMedium ??
                          const TextStyle())
                      .copyWith(color: TenantAdminColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
