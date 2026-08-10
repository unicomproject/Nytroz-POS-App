import 'package:flutter/material.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Priority Alerts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Text(
                        'View All Alerts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: Color(0xFF3B82F6)),
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
                child: Text('No alerts found.', style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(color: TenantAdminColors.mutedText)),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < alerts.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
    Color badgeColor = Colors.grey;
    Color badgeBg = Colors.grey.withValues(alpha: 0.1);
    String badgeText = alert.severity;
    Color buttonColor = const Color(0xFFF97316); // Default orange
    String buttonText = 'View';

    if (alert.severity.toLowerCase() == 'critical' || alert.severity.toLowerCase() == 'high') {
      severityColor = const Color(0xFFEF4444); // Red
      badgeColor = const Color(0xFFEF4444);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = 'High';
    } else if (alert.severity.toLowerCase() == 'warning' || alert.severity.toLowerCase() == 'medium') {
      severityColor = const Color(0xFFF97316); // Orange
      badgeColor = const Color(0xFFF97316);
      badgeBg = const Color(0xFFFFEDD5);
      badgeText = 'Medium';
    } else if (alert.severity.toLowerCase() == 'low') {
      severityColor = const Color(0xFFA855F7); // Purple
      badgeColor = const Color(0xFFA855F7);
      badgeBg = const Color(0xFFF3E8FF);
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
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
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
                  Container(
                    width: 70,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Action Button
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side: BorderSide(color: buttonColor.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

