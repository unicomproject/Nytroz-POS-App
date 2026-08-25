import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

/// A consistent, responsive workflow indicator for Tenant Admin wizards.
/// [currentStep] is zero-based so it can be used directly by existing flows.
class TenantAdminStepperHeader extends StatelessWidget {
  const TenantAdminStepperHeader({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final activeIndex = currentStep.clamp(0, steps.length - 1).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < TenantAdminBreakpoints.tablet) {
          return _CompactWorkflowHeader(
            steps: steps,
            activeIndex: activeIndex,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.xl,
            vertical: TenantAdminSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            border: Border.all(color: TenantAdminColors.border),
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  flex: 2,
                  child: _ExpandedWorkflowStep(
                    label: steps[index],
                    number: index + 1,
                    isActive: index == activeIndex,
                    isComplete: index < activeIndex,
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 17),
                      child: Container(
                        height: 2,
                        color: index < activeIndex
                            ? TenantAdminColors.primary
                            : TenantAdminColors.border,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ExpandedWorkflowStep extends StatelessWidget {
  const _ExpandedWorkflowStep({
    required this.label,
    required this.number,
    required this.isActive,
    required this.isComplete,
  });

  final String label;
  final int number;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final circleColor = isActive
        ? TenantAdminColors.primary
        : isComplete
            ? TenantAdminColors.secondary
            : TenantAdminColors.surface;
    final borderColor = isActive || isComplete
        ? TenantAdminColors.primary
        : TenantAdminColors.border;
    final labelColor = isActive
        ? TenantAdminColors.primary
        : isComplete
            ? TenantAdminColors.bodyText
            : TenantAdminColors.mutedText;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isActive ? TenantAdminShadows.card : null,
          ),
          alignment: Alignment.center,
          child: isComplete
              ? const Icon(
                  Icons.check,
                  size: 18,
                  color: TenantAdminColors.primary,
                )
              : Text(
                  '$number',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            height: 1.2,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CompactWorkflowHeader extends StatelessWidget {
  const _CompactWorkflowHeader({
    required this.steps,
    required this.activeIndex,
  });

  final List<String> steps;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final progress = (activeIndex + 1) / steps.length;
    final label = steps[activeIndex].replaceAll('\n', ' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${activeIndex + 1} of ${steps.length}',
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            label,
            style: TenantAdminTextStyles.cardTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: TenantAdminColors.primary,
              backgroundColor: TenantAdminColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
