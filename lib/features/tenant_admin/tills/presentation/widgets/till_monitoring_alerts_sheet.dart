import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till_hardware_readiness.dart';

class TillMonitoringAlertsSheet extends StatelessWidget {
  const TillMonitoringAlertsSheet({
    super.key,
    required this.readiness,
  });

  final TillHardwareReadiness readiness;

  static void show(BuildContext context, TillHardwareReadiness readiness) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TillMonitoringAlertsSheet(readiness: readiness),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: readiness.attentionReasons.isEmpty
                ? const Center(
                    child: Text(
                      'No active alerts.',
                      style: TextStyle(color: TenantAdminColors.mutedText),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                    itemCount: readiness.attentionReasons.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: TenantAdminSpacing.md),
                    itemBuilder: (context, index) {
                      return _buildAlertTile(readiness.attentionReasons[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Alerts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${readiness.alertCount} alerts for ${readiness.tillName}',
                style: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(TillAttentionReason reason) {
    Color color;
    IconData icon;

    switch (reason.severity) {
      case TillAlertSeverity.critical:
      case TillAlertSeverity.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case TillAlertSeverity.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case TillAlertSeverity.info:
      default:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                if (reason.hardwareDeviceType != null)
                  Text(
                    'Device: ${reason.hardwareDeviceType}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                if (reason.detectedAt != null)
                  Text(
                    'Detected: ${DateFormat('MMM d, h:mm a').format(reason.detectedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TenantAdminColors.mutedText,
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
