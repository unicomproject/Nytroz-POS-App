import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class OutletWizardStepper extends StatelessWidget {
  const OutletWizardStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepSelected,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.tablet;

        return Column(
          children: [
            Row(
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  _StepItem(
                    label: steps[index],
                    index: index,
                    active: index == currentStep,
                    complete: index < currentStep,
                    compact: compact,
                    onTap: index <= currentStep ? () => onStepSelected(index) : null,
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 1,
                        color: TenantAdminColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: TenantAdminColors.border),
          ],
        );
      },
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.label,
    required this.index,
    required this.active,
    required this.complete,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool active;
  final bool complete;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? TenantAdminColors.posHomeOrangeEnd
        : complete
            ? const Color(0xFF22C55E)
            : TenantAdminColors.mutedText;
    final textColor = active
        ? TenantAdminColors.posHomeOrangeEnd
        : TenantAdminColors.mutedText;

    return Semantics(
      button: onTap != null,
      selected: active,
      label: '${index + 1}. $label${complete ? ', completed' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: active
                ? const Border(bottom: BorderSide(color: TenantAdminColors.posHomeOrangeEnd, width: 2))
                : const Border(bottom: BorderSide(color: Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color,
                child: complete
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              if (!compact) ...[
                const SizedBox(width: TenantAdminSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
