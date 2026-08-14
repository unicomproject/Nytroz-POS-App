import 'package:flutter/material.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till_hardware_readiness.dart';
import '../utils/till_hardware_ui.dart';

class TillHardwareConnectionTile extends StatelessWidget {
  const TillHardwareConnectionTile({
    super.key,
    required this.connection,
  });

  final TillHardwareConnection connection;

  static const _tileBackground = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final statusUi =
        TillHardwareConnectionStatusUi.of(connection.connectionStatus);
    final subtitle = _subtitle();

    return Semantics(
      label:
          '${TillHardwareTypeUi.labelFor(connection.type)}, ${connection.name}, ${statusUi.label}',
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: _tileBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusUi.color.withValues(alpha: 0.3)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackStatus = constraints.maxWidth < 340;

            final deviceText = Row(
              children: [
                Icon(
                  TillHardwareTypeUi.iconFor(connection.type),
                  color: statusUi.color,
                  size: 22,
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TillHardwareTypeUi.labelFor(connection.type),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connection.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: TenantAdminColors.bodyText,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: connection.connectionStatus ==
                                    TillHardwareConnectionStatus.needsAttention
                                ? Colors.orange.shade800
                                : TenantAdminColors.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final status = _ConnectionStatusPill(statusUi: statusUi);

            if (stackStatus) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  deviceText,
                  const SizedBox(height: TenantAdminSpacing.sm),
                  status,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: deviceText),
                const SizedBox(width: TenantAdminSpacing.sm),
                status,
              ],
            );
          },
        ),
      ),
    );
  }

  String? _subtitle() {
    final warning = connection.warningMessage?.trim();
    if (warning != null && warning.isNotEmpty) {
      return warning;
    }

    final parts = <String>[
      if (connection.manufacturer?.trim().isNotEmpty == true)
        connection.manufacturer!.trim(),
      if (connection.model?.trim().isNotEmpty == true) connection.model!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
}

class _ConnectionStatusPill extends StatelessWidget {
  const _ConnectionStatusPill({required this.statusUi});

  final TillHardwareConnectionStatusUi statusUi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: statusUi.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusUi.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusUi.icon, color: statusUi.color, size: 15),
          const SizedBox(width: 4),
          Text(
            statusUi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: statusUi.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
