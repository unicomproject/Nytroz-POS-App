import 'package:flutter/material.dart';
import '../../../data/models/step5_barcode_dtos.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import 'edit_additional_barcode_drawer.dart';
import 'delete_barcode_dialog.dart';

class AdditionalBarcodeTable extends StatelessWidget {
  final List<Step5AdditionalBarcodeDto> additionalBarcodes;
  final List<GeneratedVariantRow> activeVariants;

  final Function(Step5AdditionalBarcodeDto, String?, int) onEdit;
  final Function(int) onDelete;
  final Function(int) onSetPrimary;

  const AdditionalBarcodeTable({
    super.key,
    required this.additionalBarcodes,
    required this.activeVariants,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (additionalBarcodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: Text('No additional barcodes assigned.',
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
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2),
          3: IntrinsicColumnWidth(), // Primary
          4: IntrinsicColumnWidth(), // Actions
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: [
          _buildHeaderRow(),
          ...additionalBarcodes
              .asMap()
              .entries
              .map((entry) => _buildDataRow(context, entry.value, entry.key)),
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
        _buildHeaderCell('Barcode Number'),
        _buildHeaderCell('Type'),
        _buildHeaderCell('Assigned To'),
        _buildHeaderCell('Primary'),
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

  TableRow _buildDataRow(
      BuildContext context, Step5AdditionalBarcodeDto barcode, int index) {
    String assignedToText = 'Base Product';
    if (barcode.productVariantId != null) {
      final variant = activeVariants.firstWhere(
        (v) => v.productVariantId == barcode.productVariantId,
        orElse: () => const GeneratedVariantRow(
            clientCombinationKey: '', combinationLabel: 'Unknown Variant'),
      );
      assignedToText = variant.displayLabel ?? variant.combinationLabel;
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(barcode.barcode, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child:
              Text(barcode.barcodeType, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(assignedToText, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: barcode.isPrimary
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text('Primary',
                        style: TextStyle(
                            fontSize: 11, color: Colors.green.shade700)),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return Align(
                            alignment: Alignment.centerRight,
                            child: Material(
                              child: EditAdditionalBarcodeDrawer(
                                barcodeDto: barcode,
                                activeVariants: activeVariants,
                                onUpdate: (updated) =>
                                    onEdit(updated, barcode.barcodeId, index),
                              ),
                            ));
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteBarcodeDialog(
                        barcode: barcode,
                        onConfirm: () => onDelete(index),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
