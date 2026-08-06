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

        final children = <Widget>[];
        for (var index = 0; index < steps.length; index++) {
          children.add(
            _StepItem(
              label: steps[index],
              index: index,
              active: index == currentStep,
              complete: index < currentStep,
              compact: compact,
              onTap: index <= currentStep ? () => onStepSelected(index) : null,
            ),
          );
          if (index < steps.length - 1) {
            children.add(
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.md),
                  height: 1.5,
                  color: index < currentStep
                      ? TenantAdminColors.primary.withValues(alpha: 0.5)
                      : TenantAdminColors.border,
                ),
              ),
            );
          }
        }

        return Row(
          children: children,
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
    final color = active || complete
        ? TenantAdminColors.primary
        : TenantAdminColors.mutedText;

    return Semantics(
      button: onTap != null,
      selected: active,
      label: '${index + 1}. $label${complete ? ', completed' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: complete
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              if (!compact) ...[
                const SizedBox(width: TenantAdminSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
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
