import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import 'parked_sales_formatters.dart';

class ParkedSaleConfirmationSummary extends StatelessWidget {
  const ParkedSaleConfirmationSummary({
    super.key,
    required this.sale,
  });

  final PosParkedSale sale;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('recall-sale-summary'),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.posHomeReturnsCard,
          border: Border.all(color: TenantAdminColors.posNewSaleAccent),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              sale.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(sale.primaryDisplayName),
            Text(
              '${sale.itemCount} items • ${formatMoney(sale.currency, sale.total)}',
            ),
            if (sale.expiresAt != null)
              Text('Expires ${formatDateTime(sale.expiresAt!)}'),
          ],
        ),
      );
}
