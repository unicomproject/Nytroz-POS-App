import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';
import 'cash_drawer_section_card.dart';

class CashDropTillInfoBar extends ConsumerWidget {
  const CashDropTillInfoBar({
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
      if (PosCashDrawerTillVisibility.canShowCashDropTill(p))
        _TillInfoItem(
          icon: Icons.point_of_sale_outlined,
          label: 'Till',
          value: summary.tillName,
          compact: compact,
        ),
      if (PosCashDrawerTillVisibility.canShowCashDropExpectedCash(p))
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
      if (PosCashDrawerTillVisibility.canShowCashDropAvailableCash(p))
        _TillInfoItem(
          icon: Icons.savings_outlined,
          label: 'Available Cash',
          value: formatCashDrawerAmount(
            summary.currentExpectedCash,
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
                if (index > 0) const SizedBox(height: TenantAdminSpacing.md),
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
          Container(
            width: compact ? 32 : 40,
            height: compact ? 32 : 40,
            decoration: BoxDecoration(
              color: TenantAdminColors.expectedCashSurface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: Icon(
              icon,
              color: TenantAdminColors.posHomeAccentOrange,
              size: compact ? 18 : 22,
            ),
          ),
          SizedBox(
            width: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TenantAdminColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: compact ? 2 : TenantAdminSpacing.xs),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: compact ? 13 : null,
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
