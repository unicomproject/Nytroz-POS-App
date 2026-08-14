import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/opening_stock_providers.dart';
import 'opening_stock_action_bar.dart';

class OpeningStockStepTwo extends ConsumerStatefulWidget {
  const OpeningStockStepTwo({super.key});

  @override
  ConsumerState<OpeningStockStepTwo> createState() =>
      _OpeningStockStepTwoState();
}

class _OpeningStockStepTwoState extends ConsumerState<OpeningStockStepTwo> {
  late TextEditingController _quantityController;
  late TextEditingController _unitCostController;
  late TextEditingController _batchController;
  late TextEditingController _notesController;

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  void initState() {
    super.initState();
    final state = ref.read(openingStockProvider);
    _quantityController = TextEditingController(
        text: state.quantity > 0 ? state.quantity.toString() : '1');
    _unitCostController = TextEditingController(
        text: state.unitCost > 0 ? state.unitCost.toString() : '0.00');
    _batchController = TextEditingController(text: state.batchNumber);
    _notesController = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);

    final canContinue = (double.tryParse(_quantityController.text) ?? 0) > 0;

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
                      'Enter Opening Stock Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Specify the initial stock quantity, cost, and optional batch details.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),

                    // Selection Banner Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product: ${state.selectedProduct?.name ?? "N/A"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: TenantAdminColors.bodyText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Outlet: ${state.selectedOutlet?.name ?? "N/A"}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => notifier.setStep(0),
                            child: const Text('Change',
                                style: TextStyle(color: primaryOrange)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    Row(
                      children: [
                        // Quantity
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Initial Quantity *',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TenantAdminColors.bodyText),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (val) {
                                  final q = double.tryParse(val) ?? 0;
                                  notifier.setQuantity(q);
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'e.g. 100',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Unit Cost
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unit Cost (LKR)',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TenantAdminColors.bodyText),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _unitCostController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (val) {
                                  final c = double.tryParse(val) ?? 0;
                                  notifier.setUnitCost(c);
                                },
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        // Batch Number
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Batch Number (Optional)',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TenantAdminColors.bodyText),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _batchController,
                                onChanged: (val) =>
                                    notifier.setBatchNumber(val),
                                decoration: InputDecoration(
                                  hintText: 'e.g. BATCH-001',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Expiry Date Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Expiry Date (Optional)',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TenantAdminColors.bodyText),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: state.expiryDate ??
                                        DateTime.now()
                                            .add(const Duration(days: 90)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 3650)),
                                  );
                                  if (picked != null) {
                                    notifier.setExpiryDate(picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        state.expiryDate != null
                                            ? "${state.expiryDate!.year}-${state.expiryDate!.month.toString().padLeft(2, '0')}-${state.expiryDate!.day.toString().padLeft(2, '0')}"
                                            : 'Select date',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: state.expiryDate != null
                                              ? TenantAdminColors.bodyText
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Notes
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes / Remarks (Optional)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TenantAdminColors.bodyText),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          onChanged: (val) => notifier.setNotes(val),
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Initial inventory count from store setup',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        OpeningStockActionBar(
          canContinue: canContinue,
          onContinue: () => notifier.nextStep(),
          continueLabel: 'Continue to Review',
        ),
      ],
    );
  }
}
