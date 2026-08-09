import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class OperationalRisksCard extends StatelessWidget {
  const OperationalRisksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: TenantAdminColors.danger, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Operational Risks & Escalations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.navy,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: TenantAdminColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                child: const Text('View All (7)'),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const Divider(height: 24),
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
          const Divider(height: 24),
          _buildRiskItem(
            icon: Icons.person_outline,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            title: '2 pending manager approvals',
            severity: 'Medium',
            severityColor: const Color(0xFF7C3AED),
            severityBg: const Color(0xFFEDE9FE),
            subtitle1: 'Approvals',
            subtitle2: 'Main Outlet',
            buttonText: 'Review Now',
            buttonColor: const Color(0xFF7C3AED),
          ),
          const Divider(height: 24),
          _buildRiskItem(
            icon: Icons.sell_outlined,
            iconColor: const Color(0xFFFF7A00),
            iconBg: const Color(0xFFFFF7ED),
            title: 'Price mismatch found on 3 SKUs',
            severity: 'Low',
            severityColor: const Color(0xFFFF7A00),
            severityBg: const Color(0xFFFFF7ED),
            subtitle1: 'Pricing',
            subtitle2: '3 Outlets',
            buttonText: 'View Details',
            buttonColor: const Color(0xFFFF7A00),
          ),
        ],
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TenantAdminColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TenantAdminColors.navy,
                ),
              ),
              Text(
                subtitle2,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: TenantAdminColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonColor,
              side: BorderSide(color: buttonColor.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: Text(buttonText),
          ),
        ),
      ],
    );
  }
}
