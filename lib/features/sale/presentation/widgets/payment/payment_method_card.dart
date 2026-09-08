import 'package:flutter/material.dart';

import '../../../domain/entities/pos_payment_method_type.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.onTap,
    this.enabled = true,
    this.selected = false,
    this.unavailableReason,
    this.onUnavailableTap,
  });

  final PosPaymentMethodType method;
  final VoidCallback onTap;
  final bool enabled;
  final bool selected;
  final String? unavailableReason;
  final VoidCallback? onUnavailableTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final accent = enabled
        ? (selected ? primaryColor : method.accentColor)
        : TenantAdminColors.mutedText;
    final titleColor =
        enabled ? TenantAdminColors.bodyText : TenantAdminColors.mutedText;
    final subtitleColor =
        enabled ? const Color(0xFF64748B) : TenantAdminColors.mutedText;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: method.title,
      hint: enabled ? method.description : unavailableReason,
      child: Material(
        color: selected ? primaryColor.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: InkWell(
          onTap: enabled ? onTap : onUnavailableTap,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              border: Border.all(
                color: selected ? primaryColor : TenantAdminColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: primaryColor,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(method.icon, color: accent, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          method.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method.description,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: subtitleColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
