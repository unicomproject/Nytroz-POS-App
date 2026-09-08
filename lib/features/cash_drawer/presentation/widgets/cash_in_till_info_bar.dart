import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';
import 'cash_drawer_section_card.dart';

class CashInTillInfoBar extends ConsumerWidget {
  const CashInTillInfoBar({
    super.key,
    required this.summary,
    this.compact = false,
  });

  final CashDrawerSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    final items = <Widget>[
      if (PosCashDrawerTillVisibility.canShowCashInTill(p))
        _TillInfoItem(
          icon: Icons.point_of_sale_outlined,
          label: 'Till',
          value: summary.tillName,
          compact: compact,
        ),
      if (PosCashDrawerTillVisibility.canShowCashInExpectedCash(p))
        _TillInfoItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Current Expected Cash',
          value: formatCashDrawerAmount(
            summary.currentExpectedCash,
            currencyCode: summary.currencyCode,
          ),
          emphasize: true,
          compact: compact,
        ),
      if (PosCashDrawerTillVisibility.canShowCashInAvailableCash(p))
        _TillInfoItem(
          icon: Icons.savings_outlined,
          label: 'Opening Cash',
          value: formatCashDrawerAmount(
            summary.openingCash,
            currencyCode: summary.currencyCode,
          ),
          emphasize: true,
          compact: compact,
        ),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return CashDrawerSectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRow = constraints.maxWidth >= TenantAdminBreakpoints.mobile;

          if (useRow) {
            return Row(
              children: [
                for (var index = 0; index < items.length; index += 1) ...[
                  if (index > 0) ...[
                    const SizedBox(width: TenantAdminSpacing.md),
                    const SizedBox(
                      height: 48,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: TenantAdminColors.border,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                  ],
                  Expanded(child: items[index]),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var index = 0; index < items.length; index += 1) ...[
                if (index > 0) const SizedBox(height: TenantAdminSpacing.sm),
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
    this.emphasize = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Row(
        children: [
          Icon(
            icon,
            size: compact ? 16 : 20,
            color: emphasize
                ? TenantAdminColors.posHomeAccentOrange
                : TenantAdminColors.mutedText,
          ),
          SizedBox(width: compact ? 6 : TenantAdminSpacing.sm),
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
                        color: emphasize
                            ? TenantAdminColors.posHomeAccentOrange
                            : TenantAdminColors.bodyText,
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
