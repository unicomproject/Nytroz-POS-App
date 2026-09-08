import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import '../../../domain/utils/variant_estimated_count_calculator.dart';

class EstimatedVariantCountCard extends StatelessWidget {
  const EstimatedVariantCountCard({
    super.key,
    required this.step4State,
    this.isLoading = false,
  });

  final Step4VariantConfigurationState step4State;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShell(
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final result = step4State.estimatedCountResult;
    final count = result.isComplete ? result.count : 0;
    final countLabel = VariantEstimatedCountCalculator.formatVariantLabel(count);
    final formulaSummary =
        VariantEstimatedCountCalculator.formatFormulaSummary(result);
    const accentColor = TenantAdminColors.posHomeAccentOrange;

    return _buildShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Variant Count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.xs,
            children: [
              Text(
                countLabel,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: result.exceedsMaximum
                      ? TenantAdminColors.danger
                      : accentColor,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'will be created',
                  style: TextStyle(
                    fontSize: 14,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          const Text(
            'Based on the selected attributes and values.',
            style: TextStyle(
              fontSize: 13,
              color: TenantAdminColors.mutedText,
            ),
          ),
          if (formulaSummary.isNotEmpty) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              formulaSummary,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TenantAdminColors.bodyText,
                height: 1.5,
              ),
            ),
          ],
          if (result.exceedsMaximum) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'Maximum of ${VariantEstimatedCountCalculator.maxVariantCombinationsPerProduct} variant combinations allowed.',
              style: TextStyle(
                fontSize: 13,
                color: TenantAdminColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (!result.isComplete &&
              step4State.attributeRows.isNotEmpty) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            const Text(
              'Complete each attribute with at least one value to preview variants.',
              style: TextStyle(
                fontSize: 13,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
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
      child: child,
    );
  }
}
