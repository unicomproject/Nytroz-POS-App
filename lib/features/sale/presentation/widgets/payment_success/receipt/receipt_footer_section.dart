import 'package:flutter/material.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_receipt_snapshot.dart';

class ReceiptFooterSection extends StatelessWidget {
  const ReceiptFooterSection({super.key, required this.presentation});

  final PosReceiptPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (presentation.thankYouMessage != null) ...[
          Text(
            presentation.thankYouMessage!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
        if (presentation.footerMessage != null) ...[
          Text(
            presentation.footerMessage!,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
        if (presentation.barcodeVisibility || presentation.qrVisibility) ...[
          // Mocking the barcode/QR for now since we just need visual representation in the preview
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                '|||||||||||||||||||||||||||||||||||||||||',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          const Text(
            'Scan to view digital receipt',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ],
    );
  }
}
