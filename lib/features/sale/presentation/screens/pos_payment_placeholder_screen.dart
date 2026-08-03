import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_checkout_summary_provider.dart';
import '../widgets/payment/payment_billing_summary_card.dart';

class PosPaymentPlaceholderScreen extends ConsumerWidget {
  const PosPaymentPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.unavailableMessage,
  });

  final String title;
  final String subtitle;
  final String? unavailableMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(posCheckoutSummaryProvider);

    return Padding(
      padding: TenantAdminInsets.pageForWidth(MediaQuery.sizeOf(context).width),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                tooltip: 'Back to payment methods',
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: TenantAdminColors.surface,
                  side: const BorderSide(color: TenantAdminColors.border),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TenantAdminTextStyles.pageTitle(context)),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(subtitle, style: TenantAdminTextStyles.muted(context)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Expanded(
            child: summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _PlaceholderMessage(
                message: 'Payment summary is unavailable.',
              ),
              data: (summary) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PaymentBillingSummaryCard(
                      itemCount: summary.itemCount,
                      subtotal: summary.subtotal,
                      discount: summary.discount,
                      tax: summary.tax,
                      totalPayable: summary.totalPayable,
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    _PlaceholderMessage(
                      message: unavailableMessage ??
                          'This payment method is not implemented yet on this device.',
                      providerUnavailable: unavailableMessage != null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderMessage extends StatelessWidget {
  const _PlaceholderMessage({
    required this.message,
    this.providerUnavailable = false,
  });

  final String message;
  final bool providerUnavailable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              providerUnavailable
                  ? Icons.credit_card_off_outlined
                  : Icons.construction_outlined,
              size: 48,
              color: TenantAdminColors.mutedText,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              providerUnavailable ? 'Card terminal unavailable' : 'Coming Soon',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}
