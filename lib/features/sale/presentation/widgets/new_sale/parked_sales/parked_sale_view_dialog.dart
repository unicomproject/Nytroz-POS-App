import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import 'parked_sales_formatters.dart';

Future<void> showParkedSaleViewDialog(
  BuildContext context,
  PosParkedSale sale,
) =>
    showAppDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('parked-sale-view-dialog'),
        title: Text('Parked Sale ${sale.reference}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: ${sale.primaryDisplayName}'),
                Text('Parked: ${formatDateTime(sale.createdAt)}'),
                if (sale.expiresAt != null)
                  Text('Expires: ${formatDateTime(sale.expiresAt!)}'),
                if (sale.note?.trim().isNotEmpty == true)
                  Text('Note: ${sale.note!.trim()}'),
                const Divider(height: TenantAdminSpacing.xxl),
                ...sale.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.product.name),
                    subtitle: Text(
                      [
                        ...item.product.selectedAttributes.values,
                        if (item.product.sku?.isNotEmpty == true)
                          'SKU: ${item.product.sku}',
                      ].join(' • '),
                    ),
                    trailing: Text(
                      '${item.quantity} × ${formatMoney(sale.currency, item.product.price)}\n${formatMoney(sale.currency, item.product.price * item.quantity)}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total ${formatMoney(sale.currency, sale.total)}',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
