import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class AddProductStepper extends StatelessWidget {
  const AddProductStepper({
    super.key,
    required this.currentStep,
    this.onStepTapped,
  });

  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  static const _steps = [
    'Basic Details',
    'Product Type & Tracking',
    'Units & Pack Conversion',
    'Product Configuration',
    'Barcode & SKU',
    'Pricing & Tax',
    'Channel Visibility',
    'Review & Create',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_steps.length, (index) {
            final stepNum = index + 1;
            final isCurrent = stepNum == currentStep;
            final isCompleted = stepNum < currentStep;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: (onStepTapped != null && isCompleted)
                      ? () => onStepTapped!(stepNum)
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.sm,
                      vertical: TenantAdminSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circle Indicator
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? TenantAdminColors.posHomeAccentOrange
                                : isCompleted
                                    ? TenantAdminColors.success
                                    : const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: isCurrent
                                  ? TenantAdminColors.posHomeAccentOrange
                                  : isCompleted
                                      ? TenantAdminColors.success
                                      : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '$stepNum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: TenantAdminSpacing.xs),
                        // Label
                        Text(
                          _steps[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent
                                ? TenantAdminColors.bodyText
                                : isCompleted
                                    ? TenantAdminColors.bodyText
                                    : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < _steps.length - 1)
                  Container(
                    width: width >= TenantAdminBreakpoints.desktop ? 24 : 12,
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isCompleted
                        ? TenantAdminColors.success
                        : const Color(0xFFE2E8F0),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
