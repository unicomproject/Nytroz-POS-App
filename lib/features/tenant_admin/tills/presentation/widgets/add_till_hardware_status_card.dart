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
    final isOnline = status.toLowerCase() == 'online' ||
        status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'connected';
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
        padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.md, vertical: TenantAdminSpacing.sm),
        child: Row(
          children: [
            // Image 2 shows actual device images, but we will use icon if we don't have images.
            // Let's use the provided icon.
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    deviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                      Expanded(
                        child: Text(
                          isOnline ? 'Connected' : status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  foregroundColor: iconColor,
                  side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
                  backgroundColor:
                      TenantAdminColors.surface.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                ),
                child: Text(actionLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
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
