import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/exchange_difference_result.dart';
import '../../../domain/entities/exchange_replacement_selection.dart';
import '../../providers/return_create_credit_provider.dart';
import 'exchange_difference_result_card.dart';

class ExchangeSummaryCard extends StatelessWidget {
  const ExchangeSummaryCard({
    super.key,
    required this.currencyCode,
    required this.returnItemValue,
    required this.newItemValue,
    required this.difference,
    this.selection,
    this.isUpdatingQuantity = false,
    this.onQuantityChanged,
    this.policyMessages = const [],
    this.canProceed = true,
    this.draftExpired = false,
    this.replacementTax = 0,
    this.replacementDiscount = 0,
  });

  final String currencyCode;
  final double returnItemValue;
  final double newItemValue;
  final ExchangeDifferencePresentation difference;
  final ExchangeReplacementSelection? selection;
  final bool isUpdatingQuantity;
  final ValueChanged<int>? onQuantityChanged;
  final List<String> policyMessages;
  final bool canProceed;
  final bool draftExpired;
  final double replacementTax;
  final double replacementDiscount;

  @override
  Widget build(BuildContext context) {
    final maxQty = selection?.availableQty?.floor();
    final quantity = selection?.quantity ?? 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exchange Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (draftExpired) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'This inspection draft has expired. Restart inspection to continue.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TenantAdminColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          if (selection != null) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            Text(
              selection!.productName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if ((selection!.variantDisplayName).trim().isNotEmpty)
              Text(
                selection!.variantDisplayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TenantAdminColors.mutedText,
                    ),
              ),
            const SizedBox(height: TenantAdminSpacing.md),
            Row(
              children: [
                Text(
                  'Qty',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                _QuantityStepper(
                  quantity: quantity,
                  maxQuantity: maxQty,
                  enabled: onQuantityChanged != null && !isUpdatingQuantity,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.lg),
          _Row(
            label: 'Return Item Value',
            value: formatReturnCreditAmount(
              currency: currencyCode,
              amount: returnItemValue,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Row(
            label: 'New Item Value',
            value: formatReturnCreditAmount(
              currency: currencyCode,
              amount: newItemValue,
            ),
          ),
          if (replacementDiscount != 0) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            _Row(
              label: 'Replacement Discount',
              value: formatReturnCreditAmount(
                currency: currencyCode,
                amount: -replacementDiscount,
              ),
            ),
          ],
          if (replacementTax != 0) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            _Row(
              label: 'Replacement Tax',
              value: formatReturnCreditAmount(
                currency: currencyCode,
                amount: replacementTax,
              ),
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.md),
          _Row(
            label: 'Difference',
            value: formatReturnCreditAmount(
              currency: currencyCode,
              amount: difference.amount == 0
                  ? 0
                  : difference.type == ExchangeDifferenceType.customerRefund
                      ? -difference.amount
                      : difference.amount,
            ),
            valueColor: TenantAdminColors.primary,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          ExchangeDifferenceResultCard(difference: difference),
          if (!canProceed && policyMessages.isNotEmpty) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            for (final message in policyMessages)
              Padding(
                padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TenantAdminColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.enabled,
    required this.onChanged,
  });

  final int quantity;
  final int? maxQuantity;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final canDecrement = enabled && quantity > 1;
    final canIncrement =
        enabled && (maxQuantity == null || quantity < maxQuantity!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: canDecrement ? () => onChanged?.call(quantity - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          visualDensity: VisualDensity.compact,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 28),
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        IconButton(
          onPressed: canIncrement ? () => onChanged?.call(quantity + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
