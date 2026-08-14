import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tenant_product_providers.dart';
import 'duplicate_barcode_banner.dart';
import 'variant_identifier_table.dart';
import 'additional_barcode_table.dart';
import 'add_additional_barcode_drawer.dart';

class Step5BarcodeSkuForm extends ConsumerWidget {
  const Step5BarcodeSkuForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addProductWizardControllerProvider);
    final controller = ref.read(addProductWizardControllerProvider.notifier);

    final step5State = state.step5State;
    final isVariant = state.productStructure == 'VARIANT';
    final optionsAsync = ref.watch(productCreateOptionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barcode & SKU',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage product codes and barcode assignments',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          if (step5State.duplicateBarcodeConflict != null)
            DuplicateBarcodeBanner(
                conflictDto: step5State.duplicateBarcodeConflict!),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Base SKU *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: step5State.baseSku,
                            onChanged: controller.updateBaseSku,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              errorText: state.fieldErrors['baseSku'] ??
                                  state.fieldErrors['sku'],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: controller.autoGenerateSku,
                          child: const Text('Auto Generate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Parent Product Barcode (Optional)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: step5State.parentProductBarcode,
                      onChanged: controller.updateParentProductBarcode,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          errorText: state.fieldErrors['parentProductBarcode'],
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () {},
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isVariant) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For VARIANT products, ensure each active variant combination receives a valid barcode or SKU.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Variant SKU & Barcode Assignment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            VariantIdentifierTable(
              activeVariants: state.step4State.generatedVariants
                  .where((v) => v.isIncluded)
                  .toList(),
              variantIdentifiers: step5State.variantIdentifiers,
              onUpdate: controller.updateVariantIdentifier,
              fieldErrors: state.fieldErrors,
            ),
          ],

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Additional Barcodes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Additional Barcode'),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                  showGeneralDialog(
                    context: context,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            child: AddAdditionalBarcodeDrawer(
                              activeVariants: state.step4State.generatedVariants
                                  .where((v) => v.isIncluded)
                                  .toList(),
                              onAdd: controller.addAdditionalBarcode,
                            ),
                          ));
                    },
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          AdditionalBarcodeTable(
            additionalBarcodes: step5State.additionalBarcodes,
            activeVariants: state.step4State.generatedVariants
                .where((v) => v.isIncluded)
                .toList(),
            onEdit: controller.editAdditionalBarcode,
            onDelete: controller.removeAdditionalBarcode,
            onSetPrimary: controller.setPrimaryBarcode,
          ),

          const SizedBox(height: 80), // bottom padding for sticky footer
        ],
      ),
    );
  }
}
