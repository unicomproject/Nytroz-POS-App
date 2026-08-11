import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/opening_stock_providers.dart';
import 'opening_stock_action_bar.dart';

class OpeningStockStepThree extends ConsumerWidget {
  const OpeningStockStepThree({super.key});

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);

    final totalValue = state.quantity * state.unitCost;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review Opening Stock Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please verify all details before submitting to the backend.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),

                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _ReviewRow(
                            label: 'Product',
                            value: state.selectedProduct?.name ?? 'N/A',
                            subValue: 'SKU: ${state.selectedProduct?.sku ?? "N/A"}',
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _ReviewRow(
                            label: 'Target Outlet',
                            value: state.selectedOutlet?.name ?? 'N/A',
                            subValue: state.selectedOutlet?.city ?? state.selectedOutlet?.location ?? '',
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _ReviewRow(
                            label: 'Quantity',
                            value: '${state.quantity.toStringAsFixed(0)} units',
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _ReviewRow(
                            label: 'Unit Cost',
                            value: 'LKR ${state.unitCost.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _ReviewRow(
                            label: 'Total Value',
                            value: 'LKR ${totalValue.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          if (state.batchNumber.isNotEmpty) ...[
                            const Divider(height: 24, color: Color(0xFFE2E8F0)),
                            _ReviewRow(
                              label: 'Batch Number',
                              value: state.batchNumber,
                            ),
                          ],
                          if (state.expiryDate != null) ...[
                            const Divider(height: 24, color: Color(0xFFE2E8F0)),
                            _ReviewRow(
                              label: 'Expiry Date',
                              value: "${state.expiryDate!.year}-${state.expiryDate!.month.toString().padLeft(2, '0')}-${state.expiryDate!.day.toString().padLeft(2, '0')}",
                            ),
                          ],
                          if (state.notes.isNotEmpty) ...[
                            const Divider(height: 24, color: Color(0xFFE2E8F0)),
                            _ReviewRow(
                              label: 'Notes',
                              value: state.notes,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        OpeningStockActionBar(
          canContinue: !state.isSubmitting,
          isLoading: state.isSubmitting,
          onContinue: () async {
            await notifier.submit();
          },
          continueLabel: 'Confirm & Submit Stock',
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.subValue,
    this.isBold = false,
  });

  final String label;
  final String value;
  final String? subValue;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? const Color(0xFFFF6A00) : TenantAdminColors.bodyText,
              ),
            ),
            if (subValue != null && subValue!.isNotEmpty)
              Text(
                subValue!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
      ],
    );
  }
}
