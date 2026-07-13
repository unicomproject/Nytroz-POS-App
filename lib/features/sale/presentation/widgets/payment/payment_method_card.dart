import 'package:flutter/material.dart';

import '../../../domain/entities/pos_payment_method_type.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.onTap,
    this.enabled = true,
  });

  final PosPaymentMethodType method;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? method.accentColor : TenantAdminColors.mutedText;
    final titleColor =
        enabled ? TenantAdminColors.bodyText : TenantAdminColors.mutedText;
    final subtitleColor =
        enabled ? TenantAdminColors.mutedText : TenantAdminColors.mutedText;

    return Material(
      color: enabled ? method.tintColor : TenantAdminColors.background,
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(method.icon, color: accent, size: 28),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.84),
                        border: Border.all(color: TenantAdminColors.border),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  method.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  method.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (!enabled) ...[
                  const SizedBox(height: TenantAdminSpacing.sm),
                  Text(
                    'Unavailable',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TenantAdminColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
