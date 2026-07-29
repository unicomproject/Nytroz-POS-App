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

        return Wrap(
          spacing: TenantAdminSpacing.sm,
          runSpacing: TenantAdminSpacing.sm,
          children: [
            for (var index = 0; index < steps.length; index++)
              _StepPill(
                label: steps[index],
                index: index,
                active: index == currentStep,
                complete: index < currentStep,
                compact: compact,
                onTap:
                    index <= currentStep ? () => onStepSelected(index) : null,
              ),
          ],
        );
      },
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
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
    final background = active
        ? TenantAdminColors.primary.withValues(alpha: 0.10)
        : TenantAdminColors.surface;

    return Semantics(
      button: onTap != null,
      selected: active,
      label: '${index + 1}. $label${complete ? ', completed' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
            vertical: TenantAdminSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color:
                  active ? TenantAdminColors.primary : TenantAdminColors.border,
            ),
            borderRadius: BorderRadius.circular(999),
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
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
