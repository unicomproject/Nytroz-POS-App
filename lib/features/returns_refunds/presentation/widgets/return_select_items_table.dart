import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../providers/return_eligibility_provider.dart';
import 'return_qty_stepper.dart';

class ReturnSelectItemsTable extends StatelessWidget {
  const ReturnSelectItemsTable({
    super.key,
    required this.items,
    required this.currency,
    required this.emptyMessage,
    this.canMutate = true,
  });

  final List<ReturnSaleLineEligibility> items;
  final String currency;
  final String emptyMessage;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: TenantAdminColors.mutedText,
              size: 34,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            children: [
              for (final item in items) ...[
                _MobileSelectableItemCard(
                  item: item,
                  currency: currency,
                  canMutate: canMutate,
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
              ],
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Column(
            children: [
              _TableHeader(visibleItems: items, canMutate: canMutate),
              for (final item in items)
                _SelectableItemRow(
                  item: item,
                  currency: currency,
                  canMutate: canMutate,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TableHeader extends ConsumerWidget {
  const _TableHeader({
    required this.visibleItems,
    required this.canMutate,
  });

  final List<ReturnSaleLineEligibility> visibleItems;
  final bool canMutate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.primary,
          fontWeight: FontWeight.w800,
        );
    final state = ref.watch(returnEligibilityProvider);
    final headerState = state.headerSelectionStateFor(visibleItems);
    final eligibleCount =
        visibleItems.where((item) => item.isSelectable).length;
    final enabled =
        canMutate && !state.isLoading && !state.isChecking && eligibleCount > 0;
    final notifier = ref.read(returnEligibilityProvider.notifier);

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Checkbox(
              tristate: true,
              value: switch (headerState) {
                HeaderSelectionState.none => false,
                HeaderSelectionState.all => true,
                HeaderSelectionState.partial => null,
              },
              onChanged: enabled
                  ? (_) => notifier.toggleSelectAllVisible(visibleItems)
                  : null,
              activeColor: TenantAdminColors.primary,
              side:
                  const BorderSide(color: TenantAdminColors.border, width: 1.5),
            ),
          ),
          Expanded(flex: 39, child: Text('Item', style: style)),
          Expanded(flex: 16, child: Text('Unit Price', style: style)),
          Expanded(flex: 13, child: Text('Purchased Qty', style: style)),
          Expanded(flex: 13, child: Text('Returned Qty', style: style)),
          Expanded(
            flex: 19,
            child: Text(
              'Return / Exchange Qty',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableItemRow extends ConsumerWidget {
  const _SelectableItemRow({
    required this.item,
    required this.currency,
    required this.canMutate,
  });

  final ReturnSaleLineEligibility item;
  final String currency;
  final bool canMutate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnEligibilityProvider);
    final selection = state.selectionFor(item.saleLineId);
    final selected = selection?.isSelected == true;
    final qty = selection?.returnQty ?? 0;
    final enabled = canMutate && !state.isLoading && item.isSelectable;
    final textColor = item.isSelectable
        ? TenantAdminColors.bodyText
        : TenantAdminColors.mutedText;
    final primaryStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w900,
        );
    final secondaryStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: item.isSelectable
              ? TenantAdminColors.primary
              : TenantAdminColors.mutedText,
          fontWeight: FontWeight.w700,
        );
    final notifier = ref.read(returnEligibilityProvider.notifier);

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: selected
            ? TenantAdminColors.primary.withValues(alpha: 0.025)
            : TenantAdminColors.surface,
        border: const Border(
          bottom: BorderSide(color: TenantAdminColors.border),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Checkbox(
              value: selected,
              onChanged: enabled
                  ? (_) => notifier.toggleItemSelection(item.saleLineId)
                  : null,
              activeColor: TenantAdminColors.primary,
              side:
                  const BorderSide(color: TenantAdminColors.border, width: 1.5),
            ),
          ),
          Expanded(
            flex: 39,
            child: Row(
              children: [
                _ProductThumb(imageValue: item.imageStorageKey),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.isEmpty ? 'Unnamed item' : item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: primaryStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.sku.isEmpty
                            ? 'SKU unavailable'
                            : 'SKU: ${item.sku}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: secondaryStyle,
                      ),
                      if (!item.isSelectable &&
                          item.ineligibilityReason != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.ineligibilityReason!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondaryStyle?.copyWith(
                            color: TenantAdminColors.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              formatReturnEligibilityAmount(
                currency: currency,
                amount: item.unitPrice,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: primaryStyle,
            ),
          ),
          Expanded(
            flex: 13,
            child: Text(_qty(item.soldQty), style: primaryStyle),
          ),
          Expanded(
            flex: 13,
            child: Text(_qty(item.returnedQty), style: primaryStyle),
          ),
          Expanded(
            flex: 19,
            child: Align(
              alignment: Alignment.centerRight,
              child: ReturnQtyStepper(
                value: qty,
                enabled: enabled && selected,
                onDecrement: () => notifier.decrementReturnQty(item.saleLineId),
                onIncrement: () => notifier.incrementReturnQty(item.saleLineId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSelectableItemCard extends ConsumerWidget {
  const _MobileSelectableItemCard({
    required this.item,
    required this.currency,
    required this.canMutate,
  });

  final ReturnSaleLineEligibility item;
  final String currency;
  final bool canMutate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnEligibilityProvider);
    final selection = state.selectionFor(item.saleLineId);
    final selected = selection?.isSelected == true;
    final qty = selection?.returnQty ?? 0;
    final enabled = canMutate && !state.isLoading && item.isSelectable;
    final notifier = ref.read(returnEligibilityProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.sm),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color:
              selected ? TenantAdminColors.primary : TenantAdminColors.border,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: enabled
                ? (_) => notifier.toggleItemSelection(item.saleLineId)
                : null,
            activeColor: TenantAdminColors.primary,
          ),
          _ProductThumb(imageValue: item.imageStorageKey),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? 'Unnamed item' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: item.isSelectable
                            ? TenantAdminColors.bodyText
                            : TenantAdminColors.mutedText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.sku.isEmpty ? 'SKU unavailable' : 'SKU: ${item.sku}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TenantAdminColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (!item.isSelectable &&
                    item.ineligibilityReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.ineligibilityReason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TenantAdminColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  formatReturnEligibilityAmount(
                    currency: currency,
                    amount: item.unitPrice,
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          ReturnQtyStepper(
            value: qty,
            enabled: enabled && selected,
            onDecrement: () => notifier.decrementReturnQty(item.saleLineId),
            onIncrement: () => notifier.incrementReturnQty(item.saleLineId),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageValue});

  final String? imageValue;
  static const _fallbackAsset = 'assets/images/product_dummy.png';

  @override
  Widget build(BuildContext context) {
    final value = imageValue?.trim() ?? '';
    final child = value.startsWith('http')
        ? Image.network(
            value,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Container(
        width: 52,
        height: 52,
        color: TenantAdminColors.background,
        child: child,
      ),
    );
  }

  Widget _fallback() {
    return Image.asset(
      _fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.inventory_2_outlined,
          color: TenantAdminColors.mutedText,
          size: 22,
        );
      },
    );
  }
}

String _qty(double value) {
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
}
