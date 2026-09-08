import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CheckoutCustomerHeader extends StatelessWidget {
  const CheckoutCustomerHeader({
    super.key,
    required this.isCreateMode,
    required this.onBack,
    this.onSkip,
  });

  final bool isCreateMode;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          final titleSection = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: TenantAdminColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: TenantAdminColors.surface,
                  size: 28,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCreateMode
                          ? 'ADD NEW CUSTOMER'
                          : 'FIND OR ADD CUSTOMER',
                      style: const TextStyle(
                        color: TenantAdminColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCreateMode
                          ? 'Enter customer name to add and attach to this sale.'
                          : 'Search by mobile number and attach the customer to this sale.',
                      style: const TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final backButton = Semantics(
            button: true,
            label: isCreateMode ? 'Back' : 'Back to Cart',
            child: OutlinedButton.icon(
              key: const ValueKey('checkout-customer-back'),
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: TenantAdminColors.border,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: TenantAdminColors.navy,
              ),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: TenantAdminColors.navy,
              ),
              label: Text(
                isCreateMode ? 'Back' : 'Back to Cart',
                style: const TextStyle(
                  color: TenantAdminColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );

          final skipButton = Semantics(
            button: true,
            label: 'SKIP',
            child: OutlinedButton.icon(
              key: const ValueKey('checkout-customer-skip'),
              onPressed: onSkip ?? onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: TenantAdminColors.primary,
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                foregroundColor: TenantAdminColors.primary,
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: TenantAdminColors.primary,
              ),
              label: const Text(
                'SKIP',
                style: TextStyle(
                  color: TenantAdminColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );

          final actionButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              backButton,
              if (!isCreateMode) ...[
                const SizedBox(width: TenantAdminSpacing.sm),
                skipButton,
              ],
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: actionButtons,
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                titleSection,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: TenantAdminSpacing.md),
              actionButtons,
            ],
          );
        },
      );
}
