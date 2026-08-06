import 'package:flutter/material.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class TillWizardStepper extends StatelessWidget {
  const TillWizardStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepSelected,
  });

  final List<({String title, String subtitle})> steps;
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
              title: steps[index].title,
              subtitle: steps[index].subtitle,
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

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: TenantAdminColors.border, width: 2),
            ),
          ),
          child: Row(
            children: children,
          ),
        );
      },
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.title,
    required this.subtitle,
    required this.index,
    required this.active,
    required this.complete,
    required this.compact,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
      label: '${index + 1}. $title${complete ? ', completed' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          decoration: BoxDecoration(
            border: active
                ? const Border(
                    bottom: BorderSide(
                      color: TenantAdminColors.primary,
                      width: 2,
                    ),
                  )
                : const Border(
                    bottom: BorderSide(
                      color: Colors.transparent,
                      width: 2,
                    ),
                  ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: TenantAdminSpacing.md,
            horizontal: TenantAdminSpacing.sm,
          ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
