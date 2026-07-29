import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../providers/return_eligibility_provider.dart';
import 'return_qty_stepper.dart';

class ReturnSoldItemRow extends ConsumerWidget {
  const ReturnSoldItemRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.returnQty,
  });

  final ReturnSaleLineEligibility item;
  final bool isSelected;
  final int returnQty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(returnEligibilityProvider.notifier);
    final currency =
        ref.watch(returnEligibilityProvider).eligibility?.currency ?? 'LKR';

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(
          color:
              isSelected ? TenantAdminColors.primary : TenantAdminColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useWideLayout =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;

          final leading = Checkbox(
            value: isSelected,
            onChanged: item.isReturnable
                ? (_) => notifier.toggleItemSelection(item.saleLineId)
                : null,
            activeColor: TenantAdminColors.primary,
          );

          final itemInfo = Expanded(
            flex: 3,
            child: Row(
              children: [
                _ItemThumbnail(name: item.name),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (item.sku.isNotEmpty) ...[
                        const SizedBox(height: TenantAdminSpacing.xs),
                        Text(
                          item.sku,
                          style: TenantAdminTextStyles.muted(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );

          final soldQty = _MetricColumn(
            label: 'Sold Qty',
            value: item.soldQty.toStringAsFixed(
              item.soldQty % 1 == 0 ? 0 : 2,
            ),
          );

          final unitPrice = _MetricColumn(
            label: 'Unit Price',
            value: formatReturnEligibilityAmount(
              currency: currency,
              amount: item.unitPrice,
            ),
          );

          final eligibilityBadge = TenantAdminStatusBadge(
            label: item.isReturnable ? 'Returnable' : 'Non-returnable',
            status: item.isReturnable
                ? TenantAdminStatusType.success
                : TenantAdminStatusType.inactive,
          );

          final qtyStepper = ReturnQtyStepper(
            value: returnQty,
            enabled: item.isReturnable,
            onDecrement: () => notifier.decrementReturnQty(item.saleLineId),
            onIncrement: () => notifier.incrementReturnQty(item.saleLineId),
          );

          if (useWideLayout) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leading,
                itemInfo,
                Expanded(child: soldQty),
                Expanded(child: unitPrice),
                Expanded(child: eligibilityBadge),
                Expanded(child: qtyStepper),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  itemInfo,
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Wrap(
                spacing: TenantAdminSpacing.lg,
                runSpacing: TenantAdminSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  soldQty,
                  unitPrice,
                  eligibilityBadge,
                  qtyStepper,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: TenantAdminColors.info,
        semanticLabel: name,
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
