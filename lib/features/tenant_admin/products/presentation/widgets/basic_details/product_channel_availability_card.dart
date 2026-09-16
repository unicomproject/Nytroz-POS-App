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
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                color: TenantAdminColors.posHomeAccentOrange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Channel Availability',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TenantAdminColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
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
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Switch.adaptive(
            value: value,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeTrackColor: TenantAdminColors.success,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
