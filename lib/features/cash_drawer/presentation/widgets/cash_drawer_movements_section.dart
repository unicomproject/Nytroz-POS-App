import 'package:flutter/material.dart';

import 'cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_movement.dart';
import '../providers/cash_drawer_provider.dart';

class CashDrawerMovementsSection extends StatelessWidget {
  const CashDrawerMovementsSection({
    super.key,
    required this.movements,
  });

  final List<CashMovement> movements;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recent Cash Movements',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (movements.isEmpty)
            _EmptyMovementsState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final useTable =
                    constraints.maxWidth >= TenantAdminBreakpoints.tablet;

                if (useTable) {
                  return _MovementsTable(movements: movements);
                }

                return Column(
                  children: [
                    for (var index = 0; index < movements.length; index += 1) ...[
                      if (index > 0) const SizedBox(height: TenantAdminSpacing.sm),
                      _MovementListCard(movement: movements[index]),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyMovementsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
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

class _MovementsTable extends StatelessWidget {
  const _MovementsTable({required this.movements});

  final List<CashMovement> movements;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 640),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(2.2),
            3: FlexColumnWidth(1.5),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: TenantAdminColors.border),
                ),
              ),
              children: const [
                _TableHeaderCell('Type'),
                _TableHeaderCell('Amount'),
                _TableHeaderCell('Date & Time'),
                _TableHeaderCell('User'),
              ],
            ),
            for (final movement in movements)
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: TenantAdminColors.border),
                  ),
                ),
                children: [
                  _TableDataCell(movement.type.label),
                  _TableDataCell(
                    _formatSignedAmount(movement),
                    color: _amountColor(movement.type),
                    fontWeight: FontWeight.w800,
                  ),
                  _TableDataCell(formatCashDrawerDateTime(movement.dateTime)),
                  _TableDataCell(movement.userName),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MovementListCard extends StatelessWidget {
  const _MovementListCard({required this.movement});

  final CashMovement movement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.type.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  formatCashDrawerDateTime(movement.dateTime),
                  style: TenantAdminTextStyles.muted(context),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  movement.userName,
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
          Text(
            _formatSignedAmount(movement),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _amountColor(movement.type),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: TenantAdminColors.mutedText,
          ),
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
      padding: const EdgeInsets.symmetric(
        vertical: TenantAdminSpacing.md,
        horizontal: TenantAdminSpacing.sm,
      ),
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

class _TableDataCell extends StatelessWidget {
  const _TableDataCell(
    this.value, {
    this.color,
    this.fontWeight,
  });

  final String value;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: TenantAdminSpacing.md,
        horizontal: TenantAdminSpacing.sm,
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? TenantAdminColors.bodyText,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
      ),
    );
  }
}

Color _amountColor(CashMovementType type) {
  return switch (type) {
    CashMovementType.cashSale || CashMovementType.cashIn => TenantAdminColors.success,
    CashMovementType.cashRefund || CashMovementType.cashOut => TenantAdminColors.danger,
    CashMovementType.cashDrop => TenantAdminColors.info,
  };
}

String _formatSignedAmount(CashMovement movement) {
  final formatted = formatCashDrawerAmount(movement.amount);
  return movement.type.isInflow ? '+ $formatted' : '- $formatted';
}
