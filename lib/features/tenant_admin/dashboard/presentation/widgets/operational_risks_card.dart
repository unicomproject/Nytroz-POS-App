import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class OperationalRisksCard extends StatelessWidget {
  const OperationalRisksCard({
    super.key,
    this.compact = false,
    this.scrollableWhenConstrained = false,
  });

  final bool compact;
  final bool scrollableWhenConstrained;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 18.0 : 22.0;
    final dividerHeight = compact ? 16.0 : 22.0;

    final riskItems = Column(
      children: [
        _buildRiskItem(
          icon: Icons.wifi_off,
          iconColor: TenantAdminColors.danger,
          iconBg: const Color(0xFFFEE2E2),
          title: 'Back Till 02 offline for 18 min',
          severity: 'High',
          severityColor: TenantAdminColors.danger,
          severityBg: const Color(0xFFFEE2E2),
          subtitle1: 'Till 02',
          subtitle2: 'Main Outlet',
          buttonText: 'Check Now',
          buttonColor: TenantAdminColors.danger,
        ),
        Divider(height: dividerHeight),
        _buildRiskItem(
          icon: Icons.inventory_2_outlined,
          iconColor: TenantAdminColors.warning,
          iconBg: const Color(0xFFFEF3C7),
          title: '42 low-stock items need reorder',
          severity: 'Medium',
          severityColor: TenantAdminColors.warning,
          severityBg: const Color(0xFFFEF3C7),
          subtitle1: 'Inventory',
          subtitle2: 'All Outlets',
          buttonText: 'Review Items',
          buttonColor: TenantAdminColors.warning,
        ),
        Divider(height: dividerHeight),
        _buildRiskItem(
          icon: Icons.person_outline,
          iconColor: TenantAdminColors.primary,
          iconBg: TenantAdminColors.secondary,
          title: '2 pending manager approvals',
          severity: 'Medium',
          severityColor: TenantAdminColors.primary,
          severityBg: TenantAdminColors.secondary,
          subtitle1: 'Approvals',
          subtitle2: 'Main Outlet',
          buttonText: 'Review Now',
          buttonColor: TenantAdminColors.primary,
        ),
        Divider(height: dividerHeight),
        _buildRiskItem(
          icon: Icons.sell_outlined,
          iconColor: TenantAdminColors.posHomeAccentOrange,
          iconBg: const Color(0xFFFFF7ED),
          title: 'Price mismatch found on 3 SKUs',
          severity: 'Low',
          severityColor: TenantAdminColors.posHomeAccentOrange,
          severityBg: const Color(0xFFFFF7ED),
          subtitle1: 'Pricing',
          subtitle2: '3 Outlets',
          buttonText: 'View Details',
          buttonColor: TenantAdminColors.posHomeAccentOrange,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final canScrollInternally =
            scrollableWhenConstrained && constraints.hasBoundedHeight;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: TenantAdminColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Operational Risks & Escalations',
                      style: TextStyle(
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.navy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: TenantAdminColors.posHomeAccentOrange,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    child: const Text('View All (7)'),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              if (canScrollInternally)
                Expanded(
                  child: SingleChildScrollView(child: riskItems),
                )
              else
                riskItems,
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String severity,
    required Color severityColor,
    required Color severityBg,
    required String subtitle1,
    required String subtitle2,
    required String buttonText,
    required Color buttonColor,
  }) {
    final iconSize = compact ? 32.0 : 38.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final iconBadge = Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: compact ? 17 : 19),
        );

        final severityBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: severityBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            severity,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: severityColor,
            ),
          ),
        );

        final actionButton = OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor.withValues(alpha: 0.3)),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 7 : 8,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(buttonText),
        );

        if (constraints.maxWidth < 390) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBadge,
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: TenantAdminColors.navy,
                      ),
                    ),
                    SizedBox(height: compact ? 3 : 5),
                    severityBadge,
                    SizedBox(height: compact ? 6 : 8),
                    Text(
                      '$subtitle1 - $subtitle2',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: actionButton,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            iconBadge,
            SizedBox(width: compact ? 12 : 14),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.navy,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  severityBadge,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle1,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.navy,
                    ),
                  ),
                  Text(
                    subtitle2,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: compact ? 96 : 108, child: actionButton),
          ],
        );
      },
    );
  }
}
