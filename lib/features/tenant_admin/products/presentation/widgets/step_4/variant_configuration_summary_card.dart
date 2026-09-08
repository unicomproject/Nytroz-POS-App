import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';

/// Post-generation sidebar summary shown beside Generated Variants.
class VariantConfigurationSummaryCard extends StatelessWidget {
  const VariantConfigurationSummaryCard({
    super.key,
    required this.step4State,
  });

  final Step4VariantConfigurationState step4State;

  @override
  Widget build(BuildContext context) {
    final total = step4State.totalGeneratedCount;
    final included = step4State.includedCount;
    final excluded = total - included;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Variant Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TenantAdminColors.subtleBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: TenantAdminColors.border),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: TenantAdminColors.mutedText,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Variants',
                      style: TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryStatusRow(
            icon: Icons.check_circle_outline,
            label: 'Included',
            count: included,
            color: TenantAdminColors.success,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _SummaryStatusRow(
            icon: Icons.remove_circle_outline,
            label: 'Excluded',
            count: excluded,
            color: TenantAdminColors.danger,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TenantAdminSpacing.sm),
            decoration: BoxDecoration(
              color: TenantAdminColors.subtleBackground,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: TenantAdminColors.mutedText,
                ),
                SizedBox(width: TenantAdminSpacing.xs),
                Expanded(
                  child: Text(
                    'Excluded variants will not be sold or stocked.',
                    style: TextStyle(
                      fontSize: 12,
                      color: TenantAdminColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatusRow extends StatelessWidget {
  const _SummaryStatusRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: TenantAdminSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.bodyText,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
