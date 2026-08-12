import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../providers/opening_stock_providers.dart';
import '../widgets/opening_stock_stepper_header.dart';
import '../widgets/opening_stock_step_one.dart';
import '../widgets/opening_stock_step_two.dart';
import '../widgets/opening_stock_step_three.dart';
import '../widgets/opening_stock_step_four.dart';

class OpeningStockWizardScreen extends ConsumerWidget {
  const OpeningStockWizardScreen({super.key});

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openingStockProvider);

    Widget currentStepWidget;
    String currentStepBreadcrumb;

    switch (state.currentStep) {
      case 0:
        currentStepWidget = const OpeningStockStepOne();
        currentStepBreadcrumb = 'Select Product & Outlet';
        break;
      case 1:
        currentStepWidget = const OpeningStockStepTwo();
        currentStepBreadcrumb = 'Enter Opening Details';
        break;
      case 2:
        currentStepWidget = const OpeningStockStepThree();
        currentStepBreadcrumb = 'Review';
        break;
      case 3:
        currentStepWidget = const OpeningStockStepFour();
        currentStepBreadcrumb = 'Success';
        break;
      default:
        currentStepWidget = const OpeningStockStepOne();
        currentStepBreadcrumb = 'Select Product & Outlet';
    }

    return TenantAdminPageScaffold(
      title: '',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Inventory',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
                    ),
                    const Text(
                      'Opening Stock',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      currentStepBreadcrumb,
                      style: const TextStyle(
                        fontSize: 12,
                        color: primaryOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Opening Stock',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: TenantAdminColors.bodyText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Select the product and outlet to add opening stock.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 14),
                          OpeningStockStepperHeader(currentStep: state.currentStep),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Opening Stock',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: TenantAdminColors.bodyText,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select the product and outlet to add opening stock.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        OpeningStockStepperHeader(currentStep: state.currentStep),
                      ],
                    );
                  },
                ),
              ],
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
