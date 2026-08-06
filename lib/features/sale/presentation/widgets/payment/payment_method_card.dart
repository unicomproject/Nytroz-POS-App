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
    final accent = enabled ? method.accentColor : TenantAdminColors.mutedText;
    final titleColor =
        enabled ? TenantAdminColors.bodyText : TenantAdminColors.mutedText;
    final subtitleColor =
        enabled ? TenantAdminColors.mutedText : TenantAdminColors.mutedText;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: method.title,
      hint: enabled ? method.description : unavailableReason,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: InkWell(
          onTap: enabled ? onTap : onUnavailableTap,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              border: Border.all(
                color: selected ? method.accentColor : TenantAdminColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: enabled
                          ? method.tintColor
                          : TenantAdminColors.background,
                    ),
                    child: Icon(method.icon, color: accent, size: 27),
                  ),
                  const SizedBox(height: 4),
                  Text(method.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: titleColor, fontWeight: FontWeight.w900)),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(method.description,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: subtitleColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
