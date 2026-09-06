import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';
import 'cash_drawer_section_card.dart';

class CloseTillTillInfoBar extends ConsumerWidget {
  const CloseTillTillInfoBar({
    super.key,
    required this.summary,
  });

  final CashDrawerSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    final items = <Widget>[
      if (PosCashDrawerTillVisibility.canShowClosingTill(p))
        _TillInfoItem(
          icon: Icons.point_of_sale_outlined,
          label: 'Till',
          value: summary.tillName,
        ),
      if (PosCashDrawerTillVisibility.canShowClosingOpenedBy(p))
        _TillInfoItem(
          icon: Icons.person_outline_rounded,
          label: 'Opened By',
          value: summary.openedBy,
        ),
      if (PosCashDrawerTillVisibility.canShowClosingOpenedTime(p))
        _TillInfoItem(
          icon: Icons.schedule_outlined,
          label: 'Opened Time',
          value: formatCashDrawerOpenedTime(summary.openedTime),
        ),
      if (PosCashDrawerTillVisibility.canShowClosingExpectedCash(p))
        _TillInfoItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Expected Cash',
          value: formatCashDrawerAmount(
            summary.currentExpectedCash,
            currencyCode: summary.currencyCode,
          ),
        ),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return CashDrawerSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useFourColumns =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;
          final useTwoColumns = !useFourColumns &&
              constraints.maxWidth >= TenantAdminBreakpoints.mobile;

          if (useFourColumns || items.length <= 2) {
            return Row(
              children: [
                for (var index = 0; index < items.length; index += 1) ...[
                  if (index > 0) const SizedBox(width: 16),
                  Expanded(child: items[index]),
                ],
              ],
            );
          }

          if (useTwoColumns) {
            final rows = <List<Widget>>[];
            for (var i = 0; i < items.length; i += 2) {
              rows.add(items.sublist(i, (i + 2).clamp(0, items.length)));
            }
            return Column(
              children: [
                for (var r = 0; r < rows.length; r++) ...[
                  if (r > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var c = 0; c < rows[r].length; c++) ...[
                        if (c > 0) const SizedBox(width: 10),
                        Expanded(child: rows[r][c]),
                      ],
                      if (rows[r].length == 1) const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var index = 0; index < items.length; index += 1) ...[
                if (index > 0) const SizedBox(height: 8),
                items[index],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TillInfoItem extends StatelessWidget {
  const _TillInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Row(
        children: [
          Icon(icon, size: 20, color: TenantAdminColors.mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TenantAdminColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
