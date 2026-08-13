import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/opening_stock_providers.dart';
import 'opening_stock_action_bar.dart';
import 'step_one/product_selection_panel.dart';
import 'step_one/outlet_selection_panel.dart';

class OpeningStockStepOne extends ConsumerWidget {
  const OpeningStockStepOne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);

    final canContinue =
        state.selectedProduct != null && state.selectedOutlet != null;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              if (isNarrow) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: const [
                      SizedBox(
                        height: 480,
                        child: ProductSelectionPanel(),
                      ),
                      SizedBox(height: 24),
                      Divider(color: Color(0xFFE2E8F0)),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 520,
                        child: OutletSelectionPanel(),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 11,
                      child: ProductSelectionPanel(),
                    ),
                    SizedBox(width: 24),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      flex: 10,
                      child: OutletSelectionPanel(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        OpeningStockActionBar(
          canContinue: canContinue,
          onContinue: () => notifier.nextStep(),
        ),
      ],
    );
  }
}
