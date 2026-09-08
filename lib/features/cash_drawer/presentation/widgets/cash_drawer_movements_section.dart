import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_movement.dart';
import '../providers/cash_drawer_provider.dart';

class CashDrawerMovementsSection extends ConsumerWidget {
  const CashDrawerMovementsSection({
    super.key,
    required this.movements,
    required this.currencyCode,
    this.compact = false,
    this.maxVisible = 8,
  });

  final List<CashMovement> movements;
  final String currencyCode;
  final bool compact;
  final int maxVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    if (!PosCashDrawerTillVisibility.canShowMovementsList(p)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'RECENT CASH MOVEMENTS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
        SizedBox(
          height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg,
        ),
        if (movements.isEmpty)
          const _EmptyMovementsState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final useTable =
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet;
              final visible = movements.take(maxVisible).toList();

              if (useTable) {
                return _MovementsTable(
                  movements: visible,
                  currencyCode: currencyCode,
                  compact: compact,
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < visible.length; index += 1) ...[
                    if (index > 0)
                      const SizedBox(height: TenantAdminSpacing.sm),
                    _MovementListCard(
                      movement: visible[index],
                      currencyCode: currencyCode,
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _EmptyMovementsState extends StatelessWidget {
  const _EmptyMovementsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: TenantAdminColors.mutedText,
            size: 32,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'No cash movements yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.bodyText,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Cash in, cash out, and sale movements will appear here.',
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
        ],
      ),
    );
  }
}

class _MovementsTable extends ConsumerWidget {
  const _MovementsTable({
    required this.movements,
    required this.currencyCode,
    required this.compact,
  });

  final List<CashMovement> movements;
  final String currencyCode;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    final showType = PosCashDrawerTillVisibility.canShowMovementType(p);
    final showAmount = PosCashDrawerTillVisibility.canShowMovementAmount(p);
    final showDate = PosCashDrawerTillVisibility.canShowMovementDate(p) ||
        PosCashDrawerTillVisibility.canShowMovementTime(p);
    final showCashier = PosCashDrawerTillVisibility.canShowMovementCashier(p);

    final headers = <Widget>[
      if (showType) const Expanded(flex: 2, child: _TableHeaderCell('Type')),
      if (showAmount)
        const Expanded(flex: 2, child: _TableHeaderCell('Amount')),
      if (showDate)
        const Expanded(flex: 2, child: _TableHeaderCell('Date & Time')),
      if (showCashier)
        const Expanded(flex: 2, child: _TableHeaderCell('User')),
    ];

    if (headers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(children: headers),
        const Divider(height: 1, color: TenantAdminColors.border),
        for (final movement in movements) ...[
          _MovementRow(
            movement: movement,
            currencyCode: currencyCode,
            compact: compact,
            showType: showType,
            showAmount: showAmount,
            showDate: showDate,
            showCashier: showCashier,
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
        ],
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.movement,
    required this.currencyCode,
    required this.compact,
    required this.showType,
    required this.showAmount,
    required this.showDate,
    required this.showCashier,
  });

  final CashMovement movement;
  final String currencyCode;
  final bool compact;
  final bool showType;
  final bool showAmount;
  final bool showDate;
  final bool showCashier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          if (showType)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    _movementIcon(movement.type),
                    size: 20,
                    color: _amountColor(movement.type),
                  ),
                  const SizedBox(width: TenantAdminSpacing.sm),
                  Flexible(
                    child: Text(
                      movement.type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          if (showAmount)
            Expanded(
              flex: 2,
              child: Text(
                _formatSignedAmount(movement, currencyCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _amountColor(movement.type),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          if (showDate)
            Expanded(
              flex: 2,
              child: Text(
                formatCashDrawerDateTime(movement.dateTime),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          if (showCashier)
            Expanded(
              flex: 2,
              child: Text(
                movement.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MovementListCard extends ConsumerWidget {
  const _MovementListCard({
    required this.movement,
    required this.currencyCode,
  });

  final CashMovement movement;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    final showType = PosCashDrawerTillVisibility.canShowMovementType(p);
    final showAmount = PosCashDrawerTillVisibility.canShowMovementAmount(p);
    final showDate = PosCashDrawerTillVisibility.canShowMovementDate(p) ||
        PosCashDrawerTillVisibility.canShowMovementTime(p);
    final showCashier = PosCashDrawerTillVisibility.canShowMovementCashier(p);

    final metaParts = <String>[
      if (showDate) formatCashDrawerDateTime(movement.dateTime),
      if (showCashier) movement.userName,
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          if (showType) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _amountColor(movement.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
              child: Icon(
                _movementIcon(movement.type),
                color: _amountColor(movement.type),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showType)
                  Text(
                    movement.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: TenantAdminColors.bodyText,
                        ),
                  ),
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    metaParts.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
              ],
            ),
          ),
          if (showAmount) ...[
            const SizedBox(width: TenantAdminSpacing.sm),
            Flexible(
              child: Text(
                _formatSignedAmount(movement, currencyCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _amountColor(movement.type),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

IconData _movementIcon(CashMovementType type) {
  return switch (type) {
    CashMovementType.cashSale => Icons.shopping_cart_outlined,
    CashMovementType.cashRefund => Icons.replay_rounded,
    CashMovementType.cashIn => Icons.arrow_downward_rounded,
    CashMovementType.cashOut => Icons.arrow_upward_rounded,
    CashMovementType.cashDrop => Icons.south_west_rounded,
  };
}

Color _amountColor(CashMovementType type) {
  return switch (type) {
    CashMovementType.cashSale ||
    CashMovementType.cashIn =>
      TenantAdminColors.success,
    CashMovementType.cashRefund ||
    CashMovementType.cashOut =>
      TenantAdminColors.danger,
    CashMovementType.cashDrop => TenantAdminColors.info,
  };
}

String _formatSignedAmount(CashMovement movement, String currencyCode) {
  final formatted =
      formatCashDrawerAmount(movement.amount, currencyCode: currencyCode);
  return movement.type.isInflow ? '+ $formatted' : '- $formatted';
}
