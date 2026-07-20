import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_sale_eligibility.dart';

class EligibilityResultBanner extends StatelessWidget {
  const EligibilityResultBanner({
    super.key,
    required this.result,
    this.onDismiss,
  });

  final ReturnSaleEligibility result;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final tone = _resolveTone(result.overallStatus);
    final title = _resolveTitle(result);
    final message = result.overallMessage.trim().isNotEmpty
        ? result.overallMessage.trim()
        : _fallbackMessage(result.overallStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tone.icon, color: tone.foreground, size: 22),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tone.foreground,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tone.foreground,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, color: tone.foreground, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  String _resolveTitle(ReturnSaleEligibility result) {
    switch (result.overallStatus) {
      case 'ELIGIBLE':
        return 'Good news! This return is eligible.';
      case 'ELIGIBLE_WITH_WARNINGS':
        return 'This return is eligible with review required.';
      case 'PARTIALLY_ELIGIBLE':
        return 'Some selected items are not eligible.';
      case 'NOT_ELIGIBLE':
        return 'This return is not eligible.';
      case 'UNDER_REVIEW':
        return 'This return requires review before continuing.';
      default:
        return 'Eligibility check completed.';
    }
  }

  String _fallbackMessage(String status) {
    switch (status) {
      case 'ELIGIBLE':
        return 'All policy requirements have been met. You can continue with the return process.';
      case 'ELIGIBLE_WITH_WARNINGS':
        return 'You can continue, but one or more checks require review during inspection.';
      case 'NOT_ELIGIBLE':
        return 'One or more policy requirements were not met for the selected items.';
      default:
        return 'Review the eligibility checklist before continuing.';
    }
  }

  _BannerTone _resolveTone(String status) {
    switch (status) {
      case 'ELIGIBLE':
        return const _BannerTone(
          background: Color(0xFFEFFAF3),
          border: Color(0xFFBBE7C8),
          foreground: Color(0xFF166534),
          icon: Icons.check_circle_rounded,
        );
      case 'ELIGIBLE_WITH_WARNINGS':
      case 'UNDER_REVIEW':
      case 'PARTIALLY_ELIGIBLE':
        return const _BannerTone(
          background: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          foreground: Color(0xFF9A3412),
          icon: Icons.schedule_rounded,
        );
      case 'NOT_ELIGIBLE':
        return const _BannerTone(
          background: Color(0xFFFEF2F2),
          border: Color(0xFFFECACA),
          foreground: Color(0xFF991B1B),
          icon: Icons.cancel_rounded,
        );
      default:
        return const _BannerTone(
          background: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
          foreground: Color(0xFF1D4ED8),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _BannerTone {
  const _BannerTone({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
