import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class TillOperationalStatusBadge extends StatelessWidget {
  const TillOperationalStatusBadge({
    super.key,
    required this.operationalStatus,
    this.attentionLabel,
  });

  final String operationalStatus;
  final String? attentionLabel;

  @override
  Widget build(BuildContext context) {
    final normalized = operationalStatus.toLowerCase();
    final color = _colorFor(normalized);
    final label = _labelFor(normalized);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.md,
            vertical: TenantAdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (attentionLabel != null && attentionLabel!.trim().isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            attentionLabel!,
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'online':
        return TenantAdminColors.success;
      case 'offline':
        return TenantAdminColors.danger;
      case 'inactive':
        return TenantAdminColors.offline;
      case 'needs_attention':
        return TenantAdminColors.warning;
      default:
        return TenantAdminColors.mutedText;
    }
  }

  String _labelFor(String status) {
    switch (status) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'inactive':
        return 'Inactive';
      case 'needs_attention':
        return 'Needs attention';
      default:
        return status;
    }
  }
}
