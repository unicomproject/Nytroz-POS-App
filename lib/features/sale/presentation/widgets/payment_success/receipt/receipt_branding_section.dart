import 'package:flutter/material.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_receipt_snapshot.dart';

class ReceiptBrandingSection extends StatelessWidget {
  const ReceiptBrandingSection({super.key, required this.branding});

  final PosReceiptBranding branding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (branding.logoUrl != null && branding.logoUrl!.isNotEmpty) ...[
          // For a real app this would be a network image, but keeping simple for snapshot
          const Icon(Icons.store_mall_directory_outlined,
              size: 48, color: Colors.black87),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
        if (branding.tradingName != null || branding.merchantName != null)
          Text(
            branding.tradingName ?? branding.merchantName ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        if (branding.outletName != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            branding.outletName!,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
        if (branding.addressLines != null &&
            branding.addressLines!.isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          for (final line in branding.addressLines!)
            Text(
              line,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
        ],
        if (branding.phone != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Tel: ${branding.phone}',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
        if (branding.taxRegistration != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Tax No: ${branding.taxRegistration}',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
