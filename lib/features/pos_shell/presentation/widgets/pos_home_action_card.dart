import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_home_action.dart';
import 'pos_dashboard_card_container.dart';

class PosHomeActionCard extends StatelessWidget {
  const PosHomeActionCard({
    super.key,
    required this.action,
    required this.icon,
    required this.description,
    required this.metrics,
    this.buttonLabel,
    this.onTap,
  });

  final PosHomeAction action;
  final IconData icon;
  final String description;
  final List<Widget> metrics;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canInvoke = action.routeExists && action.isEnabled && onTap != null;

    return PosDashboardCardContainer(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: TenantAdminColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: TenantAdminColors.info, size: 25),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            action.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          ...metrics,
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: canInvoke ? onTap : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
              child: Text(buttonLabel ?? action.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class PosActionMetricLine extends StatelessWidget {
  const PosActionMetricLine({
    super.key,
    required this.value,
    required this.label,
    this.color = TenantAdminColors.bodyText,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.xs),
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
