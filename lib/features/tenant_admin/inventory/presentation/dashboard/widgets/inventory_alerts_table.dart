import 'package:flutter/material.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../../data/models/inventory_dashboard_models.dart';

class InventoryAlertsTable extends StatelessWidget {
  const InventoryAlertsTable({
    super.key,
    required this.alerts,
  });

  final List<InventoryDashboardAlertItemDto> alerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Priority Alerts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Alerts workspace is not available in this phase (ALERTS_VIEW_ALL_DEFERRED).',
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        'View All Alerts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 16, color: TenantAdminColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xxl),
              child: Center(
                child: Text('No alerts found.',
                    style: (Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle())
                        .copyWith(color: TenantAdminColors.mutedText)),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < alerts.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: TenantAdminColors.border),
                  _AlertRow(alert: alerts[i]),
                ]
              ],
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final InventoryDashboardAlertItemDto alert;

  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    Color severityColor = Colors.grey;
    String badgeText = alert.severity;
    Color buttonColor = const Color(0xFFF97316); // Default orange
    String buttonText = 'View';

    if (alert.severity.toLowerCase() == 'critical' ||
        alert.severity.toLowerCase() == 'high') {
      severityColor = const Color(0xFFEF4444); // Red
      badgeText = 'High';
    } else if (alert.severity.toLowerCase() == 'warning' ||
        alert.severity.toLowerCase() == 'medium') {
      severityColor = const Color(0xFFF97316); // Orange
      badgeText = 'Medium';
    } else if (alert.severity.toLowerCase() == 'low') {
      severityColor = const Color(0xFFA855F7); // Purple
      badgeText = 'Low';
      buttonColor = const Color(0xFFA855F7);
      buttonText = 'Resolve';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Severity Bar
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icon
                  _buildIcon(),
                  const SizedBox(width: 16),

                  // Product Name & SKU
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          alert.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (alert.sku != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${alert.sku}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),

                  // Location
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alert.outletName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge
                  TenantAdminStatusBadge(
                    label: badgeText,
                    status: alert.severity.toLowerCase() == 'critical' ||
                            alert.severity.toLowerCase() == 'high'
                        ? TenantAdminStatusType.danger
                        : alert.severity.toLowerCase() == 'warning' ||
                                alert.severity.toLowerCase() == 'medium'
                            ? TenantAdminStatusType.warning
                            : TenantAdminStatusType.pending,
                  ),
                  const SizedBox(width: 24),

                  // Action Button
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side:
                          BorderSide(color: buttonColor.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: buttonColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: buttonColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData = Icons.warning_amber_rounded;
    Color color = Colors.red;

    if (alert.alertType.toLowerCase() == 'outofstock') {
      iconData = Icons.inventory_2_outlined;
      color = Colors.red;
    } else if (alert.alertType.toLowerCase() == 'lowstock') {
      iconData = Icons.warning_amber_rounded;
      color = Colors.red;
    } else if (alert.alertType.toLowerCase() == 'nearexpiry') {
      iconData = Icons.schedule;
      color = Colors.orange;
    } else {
      iconData = Icons.balance; // Scale icon for low severity
      color = const Color(0xFFA855F7);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Icon(iconData, color: color, size: 20),
      ),
    );
  }
}
