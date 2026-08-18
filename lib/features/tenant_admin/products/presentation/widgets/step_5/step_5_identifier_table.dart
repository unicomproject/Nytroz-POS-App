import 'package:flutter/material.dart';
import '../../../data/models/step5_barcode_dtos.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';

/// The main assignment table for Step 5 — Barcode & SKU.
/// Columns: Variant | SKU | Barcode | Scan | Status | Actions
class Step5IdentifierTable extends StatelessWidget {
  final List<BarcodeSkuAssignmentDto> assignments;
  final List<GeneratedVariantRow> allVariants;
  final String productName;
  final String productStructure;
  final void Function(BarcodeSkuAssignmentDto assignment, int index) onEdit;

  const Step5IdentifierTable({
    super.key,
    required this.assignments,
    required this.allVariants,
    required this.productName,
    required this.productStructure,
    required this.onEdit,
  });

  String _variantLabel(BarcodeSkuAssignmentDto assignment) {
    if (productStructure == 'SIMPLE' || productStructure == 'BUNDLE') {
      return productName.isNotEmpty ? productName : 'Base Product';
    }
    if (assignment.clientCombinationKey == 'SIMPLE_DEFAULT') {
      return productName.isNotEmpty ? productName : 'Base Product';
    }
    final variant = allVariants.where(
      (v) => v.clientCombinationKey == assignment.clientCombinationKey,
    );
    if (variant.isNotEmpty) {
      return variant.first.displayLabel ?? variant.first.combinationLabel;
    }
    return assignment.clientCombinationKey;
  }

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.qr_code_2_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No barcode & SKU assignments yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Select a variant and fill in SKU / Barcode above, then click Assign.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5), // Variant
            1: FlexColumnWidth(2),   // SKU
            2: FlexColumnWidth(2.5), // Barcode
            3: IntrinsicColumnWidth(), // Scan
            4: IntrinsicColumnWidth(), // Status
            5: IntrinsicColumnWidth(), // Actions
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100),
          ),
          children: [
            _buildHeaderRow(),
            ...assignments.asMap().entries.map(
              (entry) => _buildDataRow(context, entry.value, entry.key),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _headerCell('Variant'),
        _headerCell('SKU *'),
        _headerCell('Barcode'),
        _headerCell('Scan'),
        _headerCell('Status'),
        _headerCell('Actions', alignRight: true),
      ],
    );
  }

  Widget _headerCell(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  TableRow _buildDataRow(
    BuildContext context,
    BarcodeSkuAssignmentDto assignment,
    int index,
  ) {
    final variantLabel = _variantLabel(assignment);
    final effectiveStatus = assignment.effectiveStatus;

    return TableRow(
      decoration: BoxDecoration(
        color: effectiveStatus == 'DUPLICATE'
            ? const Color(0xFFFFF5F5)
            : Colors.white,
      ),
      children: [
        // Variant
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveStatus == 'COMPLETE'
                      ? Colors.green
                      : effectiveStatus == 'DUPLICATE'
                          ? Colors.red
                          : Colors.grey.shade400,
                ),
              ),
              Expanded(
                child: Text(
                  variantLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // SKU
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            assignment.sku ?? '—',
            style: TextStyle(
              fontSize: 13,
              color: assignment.sku != null ? const Color(0xFFEA580C) : Colors.grey,
              fontFamily: 'monospace',
              fontWeight: assignment.sku != null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        // Barcode
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            assignment.barcode ?? '—',
            style: TextStyle(
              fontSize: 13,
              color: assignment.barcode != null
                  ? const Color(0xFF1D4ED8)
                  : Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
        ),
        // Scan icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            color: Colors.grey.shade600,
            tooltip: 'Scan barcode',
            onPressed: () {
              // Hardware scanner will auto-fill via keyboard emulation.
              // This button serves as a visual affordance.
            },
          ),
        ),
        // Status chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: _StatusChip(status: effectiveStatus),
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: Colors.grey.shade600,
            tooltip: 'Edit',
            onPressed: () => onEdit(assignment, index),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDuplicate = status == 'DUPLICATE';
    final isComplete = status == 'COMPLETE';

    final bgColor = isDuplicate
        ? const Color(0xFFFEE2E2)
        : isComplete
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFF3F4F6);
    final fgColor = isDuplicate
        ? const Color(0xFFDC2626)
        : isComplete
            ? const Color(0xFF16A34A)
            : const Color(0xFF6B7280);
    final icon = isDuplicate
        ? Icons.error_outline
        : isComplete
            ? Icons.check_circle_outline
            : Icons.radio_button_unchecked;
    final label = isDuplicate
        ? 'Duplicate'
        : isComplete
            ? 'Complete'
            : 'Incomplete';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
