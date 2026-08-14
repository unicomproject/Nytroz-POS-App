import 'package:flutter/material.dart';
import '../../../data/models/step5_barcode_dtos.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import 'edit_variant_identifier_drawer.dart';

class VariantIdentifierTable extends StatelessWidget {
  final List<GeneratedVariantRow> activeVariants;
  final List<Step5VariantIdentifierDto> variantIdentifiers;
  final ValueChanged<Step5VariantIdentifierDto> onUpdate;
  final Map<String, String> fieldErrors;

  const VariantIdentifierTable({
    super.key,
    required this.activeVariants,
    required this.variantIdentifiers,
    required this.onUpdate,
    this.fieldErrors = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (activeVariants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: Text('No active variants to assign barcodes to.',
                style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
          3: IntrinsicColumnWidth(), // Scan
          4: IntrinsicColumnWidth(), // Status
          5: IntrinsicColumnWidth(), // Actions
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: [
          _buildHeaderRow(),
          ...activeVariants.map((v) => _buildDataRow(context, v)),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      children: [
        _buildHeaderCell('Variant'),
        _buildHeaderCell('SKU'),
        _buildHeaderCell('Barcode'),
        _buildHeaderCell('Scan'),
        _buildHeaderCell('Status'),
        _buildHeaderCell('Actions', alignRight: true),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  TableRow _buildDataRow(BuildContext context, GeneratedVariantRow variant) {
    final identifier = variantIdentifiers.firstWhere(
      (e) => e.productVariantId == variant.productVariantId,
      orElse: () => Step5VariantIdentifierDto(
          productVariantId: variant.productVariantId ?? ''),
    );

    final displayLabel = variant.displayLabel ?? variant.combinationLabel;
    final isComplete = identifier.sku != null &&
        identifier.sku!.isNotEmpty &&
        identifier.barcode != null &&
        identifier.barcode!.isNotEmpty;
    bool isDuplicate = false; // This would typically check fieldErrors or a specific duplicate map if available

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(displayLabel, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child:
              Text(identifier.sku ?? '-', style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(identifier.barcode ?? '-',
              style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            onPressed: () {
              // Scanner logic
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDuplicate
                  ? Colors.red.shade100
                  : (isComplete
                      ? Colors.green.shade100
                      : Colors.orange.shade100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isDuplicate
                  ? 'Duplicate'
                  : (isComplete ? 'Complete' : 'Incomplete'),
              style: TextStyle(
                fontSize: 11,
                color: isDuplicate
                    ? Colors.red.shade900
                    : (isComplete
                        ? Colors.green.shade900
                        : Colors.orange.shade900),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
                showGeneralDialog(
                  context: context,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          child: EditVariantIdentifierDrawer(
                            variantDto: identifier,
                            displayLabel: displayLabel,
                            onUpdate: onUpdate,
                          ),
                        ));
                  },
                );
              },
              child: const Text('Edit'),
            ),
          ),
        ),
      ],
    );
  }
}
