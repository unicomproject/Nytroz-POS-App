import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/widgets/tenant_admin_stepper_header.dart';
import '../../domain/entities/return_flow_steps.dart';

class ReturnStepper extends StatelessWidget {
  const ReturnStepper({
    super.key,
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return TenantAdminStepperHeader(
      steps: ReturnFlowSteps.labels,
      currentStep: currentStep,
    );
  }
}
