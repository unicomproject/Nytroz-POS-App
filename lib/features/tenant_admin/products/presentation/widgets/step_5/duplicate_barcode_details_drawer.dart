import 'package:flutter/material.dart';
import '../../../data/models/duplicate_barcode_conflict_dto.dart';

class DuplicateBarcodeDetailsDrawer extends StatelessWidget {
  final DuplicateBarcodeConflictDto conflictDto;

  const DuplicateBarcodeDetailsDrawer({
    super.key,
    required this.conflictDto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The following barcode or SKU is currently assigned to another record:',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  if (conflictDto.barcode != null)
                    _buildDetailRow('Barcode Number', conflictDto.barcode!),
                  if (conflictDto.barcodeType != null)
                    _buildDetailRow('Barcode Type', conflictDto.barcodeType!),
                  if (conflictDto.sku != null)
                    _buildDetailRow('SKU', conflictDto.sku!),
                  const Divider(height: 32),
                  const Text(
                    'Conflicting Record',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (conflictDto.productName != null)
                    _buildDetailRow('Product Name', conflictDto.productName!),
                  if (conflictDto.productType != null)
                    _buildDetailRow('Product Type', conflictDto.productType!),
                  if (conflictDto.variantName != null)
                    _buildDetailRow('Variant', conflictDto.variantName!),
                  if (conflictDto.assignedLevel != null)
                    _buildDetailRow(
                        'Assigned Level', conflictDto.assignedLevel!),
                  if (conflictDto.productStatus != null)
                    _buildDetailRow(
                        'Product Status', conflictDto.productStatus!),
                  if (conflictDto.stockStatus != null)
                    _buildDetailRow('Stock Status', conflictDto.stockStatus!),
                  if (conflictDto.createdBy != null)
                    _buildDetailRow('Created By', conflictDto.createdBy!),
                  if (conflictDto.createdDate != null)
                    _buildDetailRow('Created Date',
                        conflictDto.createdDate!.toIso8601String()),
                ],
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Duplicate Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          const SizedBox(width: 12),
          if (conflictDto.conflictingProductId != null)
            ElevatedButton(
              onPressed: () {
                // Navigate to product detail if permitted
                // Requires permission check logic here in a real scenario
              },
              child: const Text('View Product'),
            ),
        ],
      ),
    );
  }
}
