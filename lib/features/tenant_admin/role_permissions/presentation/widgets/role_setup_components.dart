import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step Progress Indicator – 5 numbered circles with connecting lines
// ─────────────────────────────────────────────────────────────────────────────

class RoleSetupProgressIndicator extends StatelessWidget {
  const RoleSetupProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  static const _stepLabels = [
    'Select Role',
    'Select Modules',
    'Configure\nPermissions',
    'Assign Users\n& Access',
    'Review\n& Save',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: TenantAdminSpacing.lg,
        horizontal: TenantAdminSpacing.xl,
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepBefore = (index ~/ 2) + 1;
            final isCompleted = stepBefore < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
              ),
            );
          }

          final step = (index ~/ 2) + 1;
          final isActive = step == currentStep;
          final isCompleted = step < currentStep;
          final label =
              step <= _stepLabels.length ? _stepLabels[step - 1] : 'Step $step';

          return _StepCircle(
            step: step,
            label: label,
            isActive: isActive,
            isCompleted: isCompleted,
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final int step;
  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isActive) {
      bgColor = TenantAdminColors.primary;
      textColor = Colors.white;
      borderColor = TenantAdminColors.primary;
    } else if (isCompleted) {
      bgColor = TenantAdminColors.primary;
      textColor = Colors.white;
      borderColor = TenantAdminColors.primary;
    } else {
      bgColor = TenantAdminColors.surface;
      textColor = TenantAdminColors.mutedText;
      borderColor = TenantAdminColors.border;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? TenantAdminColors.primary
                : isCompleted
                    ? TenantAdminColors.bodyText
                    : TenantAdminColors.mutedText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Header – "Step X of 5 – Title"
// ─────────────────────────────────────────────────────────────────────────────

class RoleSetupStepHeader extends StatelessWidget {
  const RoleSetupStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final int step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $step of 5 – $title',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: TenantAdminColors.mutedText,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Text(
          title,
          style: TenantAdminTextStyles.pageTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          subtitle,
          style: TenantAdminTextStyles.muted(context),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer Actions – Cancel/Back | Save Draft | Continue / Create Role
// ─────────────────────────────────────────────────────────────────────────────

class RoleSetupFooterActions extends StatelessWidget {
  const RoleSetupFooterActions({
    super.key,
    this.onBack,
    this.onSaveDraft,
    this.onContinue,
    this.backLabel,
    this.continueLabel = 'Continue →',
    this.isContinuing = false,
    this.canContinue = true,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onContinue;
  final String? backLabel;
  final String continueLabel;
  final bool isContinuing;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: TenantAdminColors.border),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onBack != null)
                OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TenantAdminColors.bodyText,
                    side: const BorderSide(color: TenantAdminColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.xl,
                      vertical: TenantAdminSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    ),
                    minimumSize: const Size(44, TenantAdminContentTokens.buttonHeight),
                  ),
                  child: Text(
                    backLabel ?? 'Cancel',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  if (onSaveDraft != null) ...[
                    OutlinedButton(
                      onPressed: onSaveDraft,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TenantAdminColors.primary,
                        side: const BorderSide(color: TenantAdminColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: TenantAdminSpacing.xl,
                          vertical: TenantAdminSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                        ),
                        minimumSize: const Size(44, TenantAdminContentTokens.buttonHeight),
                      ),
                      child: const Text(
                        'Save Draft',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                  ],
                  ElevatedButton(
                    onPressed: canContinue ? onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TenantAdminColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: TenantAdminSpacing.xl,
                        vertical: TenantAdminSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      ),
                      minimumSize: const Size(120, TenantAdminContentTokens.buttonHeight),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: isContinuing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(continueLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 13, color: TenantAdminColors.mutedText),
              const SizedBox(width: 4),
              Text(
                'All changes are tenant-specific and secure.',
                style: TextStyle(
                  fontSize: 11,
                  color: TenantAdminColors.mutedText.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Banner – Styled info/warning callout
// ─────────────────────────────────────────────────────────────────────────────

class RoleSetupInfoBanner extends StatelessWidget {
  const RoleSetupInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  final String message;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? TenantAdminColors.info;
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
            color: borderColor ?? effectiveColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 20),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TenantAdminTextStyles.muted(context).copyWith(
                color: effectiveColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Warning/Success Banner for Step 5
// ─────────────────────────────────────────────────────────────────────────────

class RoleSetupWarningBanner extends StatelessWidget {
  const RoleSetupWarningBanner({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.color = TenantAdminColors.primary,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Template Card – Radio-style selection card
// ─────────────────────────────────────────────────────────────────────────────

class HexagonIconContainer extends StatelessWidget {
  const HexagonIconContainer({
    super.key,
    required this.icon,
    required this.color,
    required this.isSelected,
    this.size = 54,
  });

  final IconData icon;
  final Color color;
  final bool isSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexagonPainter(
        color: color,
        isSelected: isSelected,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  _HexagonPainter({
    required this.color,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? color : color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w / 2, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RoleTemplateCard extends StatelessWidget {
  const RoleTemplateCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: isSelected
                ? TenantAdminColors.primary
                : TenantAdminColors.border,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? TenantAdminColors.secondary
              : TenantAdminColors.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HexagonIconContainer(
              icon: icon,
              color: color,
              isSelected: isSelected,
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? TenantAdminColors.primary
                          : TenantAdminColors.bodyText,
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    description,
                    style: TenantAdminTextStyles.muted(context).copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? TenantAdminColors.primary
                      : TenantAdminColors.border,
                  width: isSelected ? 2 : 1.5,
                ),
                color: isSelected
                    ? TenantAdminColors.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Module Card – Grid card with checkbox selection
// ─────────────────────────────────────────────────────────────────────────────

class RoleModuleCard extends StatelessWidget {
  const RoleModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isEntitled,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isEntitled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEntitled ? onTap : null,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: isSelected && isEntitled
                ? TenantAdminColors.primary
                : TenantAdminColors.border,
            width: isSelected && isEntitled ? 2 : 1,
          ),
          color: !isEntitled
              ? TenantAdminColors.subtleBackground
              : isSelected
                  ? TenantAdminColors.secondary
                  : TenantAdminColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: !isEntitled
                        ? TenantAdminColors.border
                        : isSelected
                            ? TenantAdminColors.primary.withValues(alpha: 0.12)
                            : TenantAdminColors.subtleBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: !isEntitled
                        ? TenantAdminColors.mutedText
                        : isSelected
                            ? TenantAdminColors.primary
                            : TenantAdminColors.bodyText,
                    size: 22,
                  ),
                ),
                if (isEntitled)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      activeColor: TenantAdminColors.primary,
                      side: const BorderSide(color: TenantAdminColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: !isEntitled
                    ? TenantAdminColors.mutedText
                    : isSelected
                        ? TenantAdminColors.primary
                        : TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Expanded(
              child: Text(
                description,
                style: TenantAdminTextStyles.muted(context).copyWith(
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isEntitled) ...[
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                'Not available on your subscription',
                style: TextStyle(
                  color: TenantAdminColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review Section Card – used in Step 5
// ─────────────────────────────────────────────────────────────────────────────

class RoleReviewSectionCard extends StatelessWidget {
  const RoleReviewSectionCard({
    super.key,
    required this.title,
    required this.content,
    this.onEdit,
    this.editLabel = 'Edit',
  });

  final String title;
  final Widget content;
  final VoidCallback? onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.sm,
                      vertical: TenantAdminSpacing.xs,
                    ),
                    child: Text(
                      editLabel,
                      style: const TextStyle(
                        color: TenantAdminColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          content,
        ],
      ),
    );
  }
}
