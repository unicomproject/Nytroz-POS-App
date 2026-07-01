import 'package:flutter/material.dart';

import '../../../domain/entities/pos_payment_method_type.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.onTap,
  });

  final PosPaymentMethodType method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: InkWell(
        onTap: onTap,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(method.icon, color: TenantAdminColors.info, size: 28),
                const SizedBox(height: TenantAdminSpacing.md),
                Text(
                  method.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w900,
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
