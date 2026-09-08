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

  static const steps = [
    'Basic Details',
    'Product Type & Tracking',
    'Units & Pack Conversion',
    'Product Configuration',
    'Barcode & SKU',
    'Pricing & Tax',
    'Review & Create',
  ];

  static const _compactBreakpoint = TenantAdminBreakpoints.mobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = width < _compactBreakpoint;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: isCompact
              ? _CompactStepper(
                  currentStep: currentStep,
                  onStepTapped: onStepTapped,
                )
              : _StackedStepper(
                  currentStep: currentStep,
                  onStepTapped: onStepTapped,
                ),
        );
      },
    );
  }
}

class _StackedStepper extends StatelessWidget {
  const _StackedStepper({
    required this.currentStep,
    required this.onStepTapped,
  });

  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < AddProductStepper.steps.length; index++)
          Expanded(
            child: _StepNode(
              stepNum: index + 1,
              label: AddProductStepper.steps[index],
              currentStep: currentStep,
              onStepTapped: onStepTapped,
              showLeftConnector: index > 0,
              showRightConnector: index < AddProductStepper.steps.length - 1,
            ),
          ),
      ],
    );
  }
}

class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.currentStep,
    required this.onStepTapped,
  });

  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    final safeStep = currentStep.clamp(1, AddProductStepper.steps.length);
    final currentLabel = AddProductStepper.steps[safeStep - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var index = 0;
                index < AddProductStepper.steps.length;
                index++) ...[
              _StepCircle(
                stepNum: index + 1,
                currentStep: currentStep,
                onStepTapped: onStepTapped,
                size: 24,
              ),
              if (index < AddProductStepper.steps.length - 1)
                const Expanded(
                  child: _StepConnector(),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step $safeStep of ${AddProductStepper.steps.length}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TenantAdminColors.mutedText,
          ),
        ),
        Text(
          currentLabel,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.bodyText,
          ),
        ),
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.stepNum,
    required this.label,
    required this.currentStep,
    required this.onStepTapped,
    this.showLeftConnector = false,
    this.showRightConnector = false,
  });

  final int stepNum;
  final String label;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final bool showLeftConnector;
  final bool showRightConnector;

  bool get _isCurrent => stepNum == currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              Expanded(
                child: showLeftConnector
                    ? const _StepConnector()
                    : const SizedBox.shrink(),
              ),
              _StepCircle(
                stepNum: stepNum,
                currentStep: currentStep,
                onStepTapped: onStepTapped,
                size: 24,
              ),
              Expanded(
                child: showRightConnector
                    ? const _StepConnector()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 11,
              fontWeight: _isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: _isCurrent
                  ? TenantAdminColors.posHomeAccentOrange
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.stepNum,
    required this.currentStep,
    required this.onStepTapped,
    required this.size,
  });

  final int stepNum;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isCurrent = stepNum == currentStep;
    final isCompleted = stepNum < currentStep;
    final label = AddProductStepper.steps[stepNum - 1];
    final stateLabel = isCompleted
        ? 'completed'
        : isCurrent
            ? 'current'
            : 'upcoming';

    return Semantics(
      button: isCompleted && onStepTapped != null,
      enabled: isCompleted && onStepTapped != null,
      label: 'Step $stepNum, $label, $stateLabel',
      child: InkWell(
        onTap: (onStepTapped != null && isCompleted)
            ? () => onStepTapped!(stepNum)
            : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? TenantAdminColors.posHomeAccentOrange
                : isCompleted
                    ? Colors.transparent
                    : const Color(0xFFF1F5F9),
            border: Border.all(
              color: isCurrent
                  ? TenantAdminColors.posHomeAccentOrange
                  : isCompleted
                      ? TenantAdminColors.success
                      : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: size * 0.65,
                    color: TenantAdminColors.success,
                  )
                : Text(
                    '$stepNum',
                    style: TextStyle(
                      fontSize: size * 0.46,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: isCurrent ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.0,
      color: const Color(0xFFE2E8F0),
    );
  }
}
