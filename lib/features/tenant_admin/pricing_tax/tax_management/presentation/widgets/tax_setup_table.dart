import 'package:flutter/material.dart';

import '../../../../domain/services/tenant_admin_access_checker.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/tax_aggregate.dart';
import '../utils/tax_formatters.dart';

class TaxSetupTable extends StatelessWidget {
  const TaxSetupTable({
    super.key,
    required this.items,
    required this.visibility,
    required this.onOpen,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
  });

  final List<TaxSetup> items;
  final TaxSetupListVisibility visibility;
  final ValueChanged<TaxSetup> onOpen;
  final ValueChanged<TaxSetup> onEdit;
  final ValueChanged<TaxSetup> onActivate;
  final ValueChanged<TaxSetup> onDeactivate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            const minWidth = 980.0;
            final tableWidth = width > minWidth ? width : minWidth;
            final maxHeight =
                constraints.maxHeight.isFinite ? constraints.maxHeight : 480.0;

            return SizedBox(
              height: maxHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  height: maxHeight,
                  child: Column(
                    children: [
                      const _HeaderRow(),
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: TenantAdminColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final tax = items[index];
                            return _TaxSetupRow(
                              tax: tax,
                              visibility: visibility,
                              onOpen: () => onOpen(tax),
                              onEdit: () => onEdit(tax),
                              onActivate: () => onActivate(tax),
                              onDeactivate: () => onDeactivate(tax),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Tax Name')),
          Expanded(flex: 2, child: _HeaderCell('Current Rate')),
          Expanded(flex: 3, child: _HeaderCell('Next Change')),
          Expanded(flex: 2, child: _HeaderCell('Products Using')),
          Expanded(flex: 2, child: _HeaderCell('Status')),
          SizedBox(width: 56, child: _HeaderCell('Actions')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: TenantAdminColors.mutedText,
      ),
    );
  }
}

class _TaxSetupRow extends StatelessWidget {
  const _TaxSetupRow({
    required this.tax,
    required this.visibility,
    required this.onOpen,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
  });

  final TaxSetup tax;
  final TaxSetupListVisibility visibility;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final nextChange = formatNextChange(
      nextRate: tax.nextRate,
      nextRateEffectiveFrom: tax.nextRateEffectiveFrom,
    );

    final hasActions = visibility.showEdit || visibility.showStatusManage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tax.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: TenantAdminColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tax.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    formatCurrentRateDisplay(
                      treatment: tax.taxTreatment,
                      currentRate: tax.currentRate,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    nextChange == '—' ? 'No upcoming changes' : nextChange,
                    style: TextStyle(
                      color: nextChange == '—'
                          ? TenantAdminColors.mutedText
                          : TenantAdminColors.bodyText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${tax.productCount} products',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TenantAdminStatusBadge(
                      label: tax.status.label,
                      status: tax.status.isActive
                          ? TenantAdminStatusType.active
                          : TenantAdminStatusType.inactive,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: hasActions
                        ? TenantAdminOverflowMenu(
                            actions: [
                              if (visibility.showEdit)
                                TenantAdminOverflowAction(
                                  id: 'edit',
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                  onSelected: onEdit,
                                ),
                              if (visibility.showStatusManage &&
                                  tax.status.isActive)
                                TenantAdminOverflowAction(
                                  id: 'deactivate',
                                  icon: Icons.pause_circle_outline,
                                  label: 'Deactivate',
                                  onSelected: onDeactivate,
                                ),
                              if (visibility.showStatusManage &&
                                  !tax.status.isActive)
                                TenantAdminOverflowAction(
                                  id: 'activate',
                                  icon: Icons.play_circle_outline,
                                  label: 'Activate',
                                  onSelected: onActivate,
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
