import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_inspection.dart';

class InspectionPolicyWarningCard extends StatelessWidget {
  const InspectionPolicyWarningCard({
    super.key,
    required this.messages,
  });

  final List<InspectionPolicyMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final message in messages) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            decoration: BoxDecoration(
              color: TenantAdminColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(
                color: TenantAdminColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: TenantAdminColors.warning,
                  size: 20,
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Text(
                    message.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
      ],
    );
  }
}
