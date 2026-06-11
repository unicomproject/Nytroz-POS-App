import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < TenantAdminBreakpoints.mobile;

        return Wrap(
          spacing: TenantAdminSpacing.sm,
          runSpacing: TenantAdminSpacing.sm,
          children: [
            for (var index = 0; index < steps.length; index++)
              _StepperPill(
                label: steps[index],
                index: index,
                active: index == currentStep,
                complete: index < currentStep,
                compact: isNarrow,
              ),
          ],
        );
      },
    );
  }
}

class _StepperPill extends StatelessWidget {
  const _StepperPill({
    required this.label,
    required this.index,
    required this.active,
    required this.complete,
    required this.compact,
  });

  final String label;
  final int index;
  final bool active;
  final bool complete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = active || complete
        ? TenantAdminColors.primary
        : TenantAdminColors.mutedText;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: active
            ? TenantAdminColors.primary.withValues(alpha: 0.10)
            : TenantAdminColors.surface,
        border: Border.all(color: active ? TenantAdminColors.primary : TenantAdminColors.border),
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
    );
  }
}
