import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../providers/return_create_credit_provider.dart';

class ReturnCreditPreviewCard extends StatelessWidget {
  const ReturnCreditPreviewCard({
    super.key,
    required this.preview,
  });

  final ReturnCreditPreview preview;

  @override
  Widget build(BuildContext context) {
    final currency = preview.currency;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: TenantAdminColors.success,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(
                'Customer Credit Preview',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: TenantAdminColors.border),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: TenantAdminColors.primary,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.customerName.isEmpty
                          ? 'Walk-in customer'
                          : preview.customerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (preview.customerDisplayId.isNotEmpty) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        'Customer ID: ${preview.customerDisplayId}',
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _PreviewField(
            label: 'Credit Reference',
            value: preview.creditReference,
            valueColor: TenantAdminColors.primary,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Credit Amount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            formatReturnCreditAmount(
              currency: currency,
              amount: preview.calculation.netCreditAmount,
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: TenantAdminColors.success,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: TenantAdminColors.success,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Text(
                  'Valid for ${preview.validityDays} days from issue date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Usable for future purchases only.',
            style: TenantAdminTextStyles.muted(context),
          ),
        ],
      ),
    );
  }
}

class _PreviewField extends StatelessWidget {
  const _PreviewField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
