import 'package:flutter/material.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../../domain/entities/pos_online_order_collection.dart';
import '../online_order_ui.dart';

class CollectionVerificationSummary extends StatelessWidget {
  const CollectionVerificationSummary({
    required this.result,
    super.key,
  });

  final PosCollectionValidationResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.orderNumber,
                    style: OnlineOrderUi.title,
                  ),
                ),
                if (result.pickupNumber.isNotEmpty)
                  Chip(
                    label: Text('Pickup #${result.pickupNumber}'),
                    backgroundColor: scheme.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result.customerName?.isNotEmpty == true
                  ? result.customerName!
                  : 'Customer',
              style: OnlineOrderUi.subtitle.copyWith(
                color: OnlineOrderUi.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (result.customerPhone?.isNotEmpty == true)
              Text(result.customerPhone!, style: OnlineOrderUi.subtitle),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaChip(
                  label: 'Payment',
                  value: result.paymentStatus,
                ),
                _MetaChip(
                  label: 'Pickup',
                  value: result.pickupStatus,
                ),
                _MetaChip(
                  label: 'Total',
                  value: OnlineOrderUi.money(result.currency, result.total),
                ),
                if (result.balanceDue > 0)
                  _MetaChip(
                    label: 'Balance due',
                    value:
                        OnlineOrderUi.money(result.currency, result.balanceDue),
                    emphasize: true,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Packed items',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: OnlineOrderUi.ink,
              ),
            ),
            const SizedBox(height: 8),
            ...result.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(item.productName),
                trailing: Text(
                  '× ${item.quantityPacked % 1 == 0 ? item.quantityPacked.toInt() : item.quantityPacked}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: emphasize ? TenantAdminColors.warningSurface : TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OnlineOrderUi.subtitle.copyWith(fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: emphasize ? TenantAdminColors.warning : OnlineOrderUi.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionHandoverChecklist extends StatelessWidget {
  const CollectionHandoverChecklist({
    required this.checked,
    required this.onChanged,
    super.key,
  });

  final List<bool> checked;
  final ValueChanged<int> onChanged;

  static const labels = [
    'Customer identity matches the order',
    'All packed items are present',
    'Outstanding payment is settled (if any)',
    'Customer is ready to take the order',
  ];

  bool get allChecked => checked.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < labels.length; i++)
              CheckboxListTile(
                value: i < checked.length ? checked[i] : false,
                onChanged: (_) => onChanged(i),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(labels[i]),
              ),
          ],
        ),
      ),
    );
  }
}
