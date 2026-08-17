import 'package:flutter/material.dart';

import '../../widgets/inventory_shared_widgets.dart';

class OpeningStockStepperHeader extends StatelessWidget {
  const OpeningStockStepperHeader({
    super.key,
    required this.currentStep,
  });

  final int currentStep;

  static const List<String> _stepTitles = [
    'Select Product & Outlet',
    'Enter Opening Details',
    'Review',
    'Success',
  ];

  @override
  Widget build(BuildContext context) {
    return InventoryStepper(
      steps: _stepTitles,
      currentIndex: currentStep,
    );
  }
}
