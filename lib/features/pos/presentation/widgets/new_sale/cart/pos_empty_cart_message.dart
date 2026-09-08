import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_sales_permission_visibility.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosEmptyCartMessage extends ConsumerWidget {
  const PosEmptyCartMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!PosSalesPermissionVisibility.canShowEmptyCartMessage(permissions)) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 150;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_shopping_cart_rounded,
                size: compact ? 36 : 56,
                color: TenantAdminColors.offline,
              ),
              SizedBox(
                height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
              ),
              Text(
                'No items added',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (!compact) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Select a product to prepare the sale.',
                  textAlign: TextAlign.center,
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
