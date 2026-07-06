import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnCompletedSuccessBanner extends StatelessWidget {
  const ReturnCompletedSuccessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: TenantAdminColors.success,
              size: 32,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Return processed successfully!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'The refund has been issued and the return is complete.',
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
