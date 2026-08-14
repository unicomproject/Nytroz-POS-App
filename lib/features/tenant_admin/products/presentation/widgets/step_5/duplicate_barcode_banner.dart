import 'package:flutter/material.dart';
import '../../../data/models/duplicate_barcode_conflict_dto.dart';
import 'duplicate_barcode_details_drawer.dart';

class DuplicateBarcodeBanner extends StatelessWidget {
  final DuplicateBarcodeConflictDto conflictDto;

  const DuplicateBarcodeBanner({
    super.key,
    required this.conflictDto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duplicate Barcode or SKU Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This barcode or SKU is already assigned to another product or variant in your tenant.',
                  style: TextStyle(
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Open details drawer
              Scaffold.of(context)
                  .openEndDrawer(); // Assuming drawer is attached to scaffold
              showGeneralDialog(
                context: context,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        child: DuplicateBarcodeDetailsDrawer(
                            conflictDto: conflictDto),
                      ));
                },
              );
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}
