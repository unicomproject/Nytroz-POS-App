import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/checkout_customer_provider.dart';

class CustomerMobileInput extends StatelessWidget {
  const CustomerMobileInput({
    super.key,
    required this.state,
    required this.canCreate,
    required this.canAttach,
    required this.onDialCodeChanged,
    required this.onRetrySearch,
    required this.onConfirmFound,
    required this.onBeginCreate,
    this.isStacked = false,
  });

  final CheckoutCustomerState state;
  final bool canCreate;
  final bool canAttach;
  final ValueChanged<String> onDialCodeChanged;
  final VoidCallback onRetrySearch;
  final VoidCallback onConfirmFound;
  final VoidCallback onBeginCreate;
  final bool isStacked;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: TenantAdminColors.subtleBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: TenantAdminColors.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              const Expanded(
                child: Text(
                  'Search by Mobile Number',
                  style: TextStyle(
                    color: TenantAdminColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              // Country / Dial Code Selector
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface,
                  border: Border.all(color: TenantAdminColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.dialCode.isNotEmpty ? state.dialCode : '+94',
                      key: const ValueKey('checkout-customer-dial-code'),
                      style: const TextStyle(
                        color: TenantAdminColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: TenantAdminColors.navy,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Mobile Number Field
              Expanded(
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: TenantAdminColors.surface,
                    border: Border.all(color: TenantAdminColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.localPhone.isNotEmpty
                        ? state.localPhone
                        : 'Enter mobile number',
                    style: TextStyle(
                      color: state.localPhone.isNotEmpty
                          ? TenantAdminColors.navy
                          : TenantAdminColors.mutedText,
                      fontWeight: state.localPhone.isNotEmpty
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: state.localPhone.isNotEmpty ? 20 : 17,
                      letterSpacing: state.localPhone.isNotEmpty ? 1.5 : 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          const Text(
            'Search starts automatically when a valid mobile number is entered.',
            style: TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          // Dynamic State Section
          if (state.stage == CheckoutCustomerStage.searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
              child: _StateMessage(
                key: ValueKey('checkout-customer-searching'),
                icon: Icons.search,
                title: 'Looking for customer...',
              ),
            ),
          if (state.stage == CheckoutCustomerStage.customerFound &&
              state.foundCustomer != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StateMessage(
                    key: const ValueKey('checkout-customer-found'),
                    icon: Icons.person_outline,
                    title: state.foundCustomer!.displayName,
                    subtitle:
                        '${state.foundCustomer!.phone ?? ''}${state.foundCustomer!.totalOrderCount > 0 ? '\nPrevious orders: ${state.foundCustomer!.totalOrderCount}' : ''}',
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  if (canAttach)
                    FilledButton(
                      key: const ValueKey('checkout-customer-confirm-found'),
                      style: FilledButton.styleFrom(
                        backgroundColor: TenantAdminColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onConfirmFound,
                      child: const Text(
                        'ADD TO SALE & CONTINUE',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          if (state.stage == CheckoutCustomerStage.customerNotFound)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _StateMessage(
                    key: ValueKey('checkout-customer-not-found'),
                    icon: Icons.person_off_outlined,
                    title: 'No customer found',
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  FilledButton(
                    key: const ValueKey('checkout-customer-add-new'),
                    style: FilledButton.styleFrom(
                      backgroundColor: TenantAdminColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: canCreate ? onBeginCreate : null,
                    child: const Text(
                      'ADD AS NEW CUSTOMER',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (!canCreate) ...[
                    const SizedBox(height: TenantAdminSpacing.xs),
                    const Text(
                      'Customer creation permission is required.',
                      style: TextStyle(
                        color: TenantAdminColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (state.stage == CheckoutCustomerStage.searchError ||
              state.stage == CheckoutCustomerStage.checkoutRevalidationError)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StateMessage(
                    key: const ValueKey('checkout-customer-error'),
                    icon: Icons.error_outline,
                    title: state.error ?? 'Unable to continue',
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  OutlinedButton(
                    onPressed: onRetrySearch,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          // Flexible spacer pushing info card to the bottom on unstacked layouts
          if (!isStacked)
            const Spacer()
          else
            const SizedBox(height: TenantAdminSpacing.lg),
          // Target Bottom Info Card
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: TenantAdminColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TenantAdminColors.info.withValues(alpha: 0.18),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: TenantAdminColors.info,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Only mobile number is required to find a customer.',
                    style: TextStyle(
                      color: TenantAdminColors.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: TenantAdminColors.primary),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: TenantAdminColors.navy,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
