import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till_create_options.dart';

class AddTillHardwareStatusCard extends StatelessWidget {
  const AddTillHardwareStatusCard({
    super.key,
    required this.deviceCode,
    required this.deviceName,
    required this.type,
    required this.status,
    required this.icon,
    this.actionLabel = 'Test',
    this.onAction,
  });

  final String deviceCode;
  final String deviceName;
  final String type;
  final String status;
  final IconData icon;
  final String actionLabel;
  final VoidCallback? onAction;

  factory AddTillHardwareStatusCard.fromOption(
    TillHardwareDeviceOption option,
    IconData icon,
    String actionLabel,
    VoidCallback? onAction,
  ) {
    return AddTillHardwareStatusCard(
      deviceCode: option.code,
      deviceName: option.name,
      type: option.type,
      status: option.status,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory AddTillHardwareStatusCard.fromPos(
    TillPosDeviceOption option,
    IconData icon,
    String actionLabel,
    VoidCallback? onAction,
  ) {
    return AddTillHardwareStatusCard(
      deviceCode: option.code,
      deviceName: option.name,
      type: 'POS Device',
      status: option.status,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = status.toLowerCase() == 'online';
    final statusColor =
        isOnline ? TenantAdminColors.success : TenantAdminColors.mutedText;

    Color cardBgColor;
    Color iconColor;
    final lowerType = type.toLowerCase();
    if (lowerType.contains('scanner')) {
      cardBgColor = TenantAdminColors.posHomeCashCard; // green-ish
      iconColor = TenantAdminColors.success;
    } else if (lowerType.contains('printer')) {
      cardBgColor = TenantAdminColors.posHomeSaleCard; // blue-ish
      iconColor = TenantAdminColors.info;
    } else if (lowerType.contains('drawer')) {
      cardBgColor = TenantAdminColors.posHomeOrdersCard; // purple-ish
      iconColor = TenantAdminColors.pending;
    } else {
      cardBgColor = TenantAdminColors.secondary;
      iconColor = TenantAdminColors.primary;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        side: BorderSide(
            color: TenantAdminColors.border.withValues(alpha: 0.5), width: 1),
      ),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: TenantAdminColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onAction != null)
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: TenantAdminColors.bodyText,
                  side: const BorderSide(color: TenantAdminColors.border),
                  backgroundColor: TenantAdminColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                ),
                child: Text(actionLabel, style: const TextStyle(fontSize: 13)),
              )
            else
              TextButton(
                onPressed: null,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
