import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ProductChannelAvailabilityCard extends StatelessWidget {
  const ProductChannelAvailabilityCard({
    super.key,
    required this.posSellable,
    required this.allowOnlineSale,
    required this.onPosSellableChanged,
    required this.onAllowOnlineSaleChanged,
  });

  final bool posSellable;
  final bool allowOnlineSale;

  final ValueChanged<bool> onPosSellableChanged;
  final ValueChanged<bool> onAllowOnlineSaleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Channel Availability',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _buildToggleTile(
            title: 'In-Store POS',
            subtitle: 'Enable to sell in POS',
            value: posSellable,
            onChanged: onPosSellableChanged,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildToggleTile(
            title: 'Online Store',
            subtitle: 'Make product available online',
            value: allowOnlineSale,
            onChanged: onAllowOnlineSaleChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: TenantAdminColors.success,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
