import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_resolution_type.dart';

class ReturnStepper extends StatelessWidget {
  const ReturnStepper({
    super.key,
    required this.currentStep,
    this.selectedBranch,
  });

  final ReturnsExchangeStep currentStep;
  final ReturnResolutionType? selectedBranch;

  static String branchStepLabel(ReturnResolutionType? branch) {
    switch (branch) {
      case ReturnResolutionType.refund:
        return 'Refund';
      case ReturnResolutionType.exchange:
        return 'Exchange';
      case null:
        return 'Refund / Exchange';
    }
  }

  static const _visualSteps = [
    _ReturnVisualStep('1', 'Search Sale', ReturnsExchangeStep.searchSale),
    _ReturnVisualStep('2', 'Sale Summary', ReturnsExchangeStep.saleSummary),
    _ReturnVisualStep('3', 'Select Items', ReturnsExchangeStep.selectItems),
    _ReturnVisualStep(
      '4',
      'Check Eligibility',
      ReturnsExchangeStep.checkEligibility,
    ),
    _ReturnVisualStep('5', 'Return Reason', ReturnsExchangeStep.returnReason),
    _ReturnVisualStep('6', 'Inspect Items', ReturnsExchangeStep.inspectItems),
    _ReturnVisualStep('7', 'Choose Option', ReturnsExchangeStep.chooseOption),
    _ReturnVisualStep(
      '8',
      'Refund / Exchange',
      ReturnsExchangeStep.branchAction,
      dynamicLabel: true,
    ),
    _ReturnVisualStep(
      '9',
      'Review & Confirm',
      ReturnsExchangeStep.reviewAndConfirm,
    ),
    _ReturnVisualStep(
      '10',
      'Receipt / Success',
      ReturnsExchangeStep.receiptSuccess,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final tablet = constraints.maxWidth < 1120;
        final stepWidth = compact
            ? 44.0
            : tablet
                ? 70.0
                : 78.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < _visualSteps.length; index++) ...[
                _StepTile(
                  step: _visualSteps[index],
                  label: _labelForStep(_visualSteps[index]),
                  active: _isActive(_visualSteps[index]),
                  complete: _isComplete(_visualSteps[index]),
                  compact: compact,
                  width: stepWidth,
                ),
                if (index < _visualSteps.length - 1)
                  _StepConnector(
                    active: _isComplete(_visualSteps[index + 1]) ||
                        _isActive(_visualSteps[index + 1]),
                    compact: compact,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _labelForStep(_ReturnVisualStep step) {
    if (step.dynamicLabel) {
      return branchStepLabel(selectedBranch);
    }
    return step.label;
  }

  bool _isActive(_ReturnVisualStep step) {
    return step.flowStep == currentStep;
  }

  bool _isComplete(_ReturnVisualStep step) {
    return step.flowStep.index < currentStep.index;
  }
}

class _ReturnVisualStep {
  const _ReturnVisualStep(
    this.number,
    this.label,
    this.flowStep, {
    this.dynamicLabel = false,
  });

  final String number;
  final String label;
  final ReturnsExchangeStep flowStep;
  final bool dynamicLabel;
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.label,
    required this.active,
    required this.complete,
    required this.compact,
    required this.width,
  });

  final _ReturnVisualStep step;
  final String label;
  final bool active;
  final bool complete;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = active || complete
        ? TenantAdminColors.primary
        : TenantAdminColors.mutedText;
    final background = active
        ? TenantAdminColors.primary.withValues(alpha: 0.10)
        : TenantAdminColors.background;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 24 : 30,
            height: compact ? 24 : 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  active || complete ? TenantAdminColors.primary : background,
              shape: BoxShape.circle,
              border: Border.all(
                color: active || complete ? TenantAdminColors.primary : color,
                width: active ? 2 : 1,
              ),
            ),
            child: complete
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    step.number,
                    style: TextStyle(
                      color: active ? Colors.white : color,
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 9 : 11,
                    ),
                  ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            label,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active
                      ? TenantAdminColors.primary
                      : TenantAdminColors.bodyText,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                  fontSize: compact ? 9 : 9.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({
    required this.active,
    required this.compact,
  });

  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 10 : 24,
      height: 2,
      margin: EdgeInsets.only(bottom: compact ? 18 : 18),
      color: active ? TenantAdminColors.primary : TenantAdminColors.border,
    );
  }
}
