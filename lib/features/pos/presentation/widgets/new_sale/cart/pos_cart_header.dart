import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosCartHeader extends ConsumerWidget {
  const PosCartHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posNewSaleCartProvider);
    final selectedCustomer = cart.selectedCustomer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: TenantAdminColors.posHomeAccentOrange,
              size: 24,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Text(
                'Current Sale',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
                vertical: TenantAdminSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                border: Border.all(color: const Color(0xFFEFF6FF)),
              ),
              child: Text(
                '${cart.itemList.length} Lines • '
                '${cart.itemList.fold<int>(0, (total, item) => total + item.quantity)} Items',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        if (selectedCustomer != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Wrap(
            spacing: TenantAdminSpacing.xs,
            runSpacing: TenantAdminSpacing.xs,
            children: [
              Chip(
                label: Text(selectedCustomer.displayName),
                avatar: const Icon(Icons.person_outline_rounded, size: 18),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
