import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../../presentation/widgets/tenant_admin_stepper_header.dart';
import '../providers/opening_stock_providers.dart';
import '../widgets/opening_stock_step_one.dart';
import '../widgets/opening_stock_step_two.dart';
import '../widgets/opening_stock_step_three.dart';
import '../widgets/opening_stock_step_four.dart';

class OpeningStockWizardScreen extends ConsumerWidget {
  const OpeningStockWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openingStockProvider);

    Widget currentStepWidget;

    switch (state.currentStep) {
      case 0:
        currentStepWidget = const OpeningStockStepOne();
        break;
      case 1:
        currentStepWidget = const OpeningStockStepTwo();
        break;
      case 2:
        currentStepWidget = const OpeningStockStepThree();
        break;
      case 3:
        currentStepWidget = const OpeningStockStepFour();
        break;
      default:
        currentStepWidget = const OpeningStockStepOne();
    }

    final stepTitles = [
      'Select Product & Outlet',
      'Enter Opening Details',
      'Review',
      'Success',
    ];

    return TenantAdminPageScaffold(
      title: 'Opening Stock',
      subtitle: 'Select the product and outlet to add opening stock.',
      scrollable: false,
      showBackButton: true,
      onBackButtonPressed: () {
        if (state.currentStep == 0 || state.currentStep == 3) {
          context.go('/tenant-admin/stock/dashboard');
        } else {
          ref.read(openingStockProvider.notifier).previousStep();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: TenantAdminStepperHeader(
              steps: stepTitles,
              currentStep: state.currentStep,
            ),
          ),
          Expanded(
            child: currentStepWidget,
          ),
        ],
      ),
    );
  }
}
