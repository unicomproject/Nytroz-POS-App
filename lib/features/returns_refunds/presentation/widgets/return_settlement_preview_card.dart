import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_settlement_method.dart';
import '../providers/return_create_credit_provider.dart';

class ReturnSettlementPreviewCard extends StatelessWidget {
  const ReturnSettlementPreviewCard({
    super.key,
    required this.preview,
    required this.values,
  });

  final ReturnCreditPreview preview;
  final ReturnSettlementPreviewValues values;

  @override
  Widget build(BuildContext context) {
    final currency = preview.currency;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            values.previewTitle,
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _PreviewRow(
            label: 'Refund Amount',
            value: formatReturnCreditAmount(
              currency: currency,
              amount: values.refundAmount,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _PreviewRow(
            label: 'Refund Method',
            value: values.refundMethodLabel,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _PreviewRow(
            label: 'Customer Credit',
            value: formatReturnCreditAmount(
              currency: currency,
              amount: values.customerCreditAmount,
            ),
            emphasize: true,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: TenantAdminColors.border),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: TenantAdminColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: TenantAdminColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      preview.customerName.isEmpty
                          ? 'Walk-in customer'
                          : preview.customerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TenantAdminTextStyles.muted(context),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: emphasize ? TenantAdminColors.primary : null,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
