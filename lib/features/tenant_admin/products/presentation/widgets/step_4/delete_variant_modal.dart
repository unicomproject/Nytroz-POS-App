import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class DeleteVariantModal extends ConsumerWidget {
  final AddProductWizardController controller;
  final String variantKey;
  final String variantLabel;

  const DeleteVariantModal({
    super.key,
    required this.controller,
    required this.variantKey,
    required this.variantLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Delete Variant',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.danger)),
      content: const Text(
        'Are you sure you want to delete this variant? This action will tombstone the variant and it will no longer be available for sale.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TenantAdminColors.danger,
          ),
          onPressed: () {
            controller.confirmDeleteVariant(variantKey);
            Navigator.of(context).pop();
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
