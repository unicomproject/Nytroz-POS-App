import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

import 'product_basic_details_form.dart';
import 'product_image_upload_card.dart';
import 'product_channel_availability_card.dart';

class Step1BasicDetails extends StatelessWidget {
  const Step1BasicDetails({
    super.key,
    required this.state,
    required this.controller,
    required this.nameController,
    required this.codeController,
    required this.shortDescriptionController,
    required this.longDescriptionController,
  });

  final AddProductWizardState state;
  final AddProductWizardController controller;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController shortDescriptionController;
  final TextEditingController longDescriptionController;

  Future<void> _pickImage({VoidCallback? onStartUpload}) async {
    try {
      final picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();
      if (files.isNotEmpty) {
        onStartUpload?.call();
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final fileName = file.name;
          String mimeType = file.mimeType ?? '';
          if (mimeType.isEmpty || mimeType == 'application/octet-stream') {
            final lower = fileName.toLowerCase();
            if (lower.endsWith('.png')) {
              mimeType = 'image/png';
            } else if (lower.endsWith('.webp')) {
              mimeType = 'image/webp';
            } else {
              mimeType = 'image/jpeg';
            }
          }
          await controller.stageOrUploadImage(bytes, fileName, mimeType);
        }
      }
    } catch (e) {
      // Ignore or state handles error
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= TenantAdminBreakpoints.desktop;

    final options = state.createOptions;
    if (options == null) {
      return const SizedBox.shrink();
    }

    final imageCard = ProductImageUploadCard(
      images: state.productImages,
      onPickImage: _pickImage,
      onSetPrimary: controller.setPrimaryImage,
      onDelete: controller.deleteImage,
    );

    return Stack(
      children: [
        // Main Form Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.pageError != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.md,
                  vertical: TenantAdminSpacing.sm,
                ),
                margin: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: TenantAdminColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.pageError!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.danger,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: TenantAdminColors.danger, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Dismiss',
                      onPressed: controller.clearPageError,
                    ),
                  ],
                ),
              ),
            ],
            if (isDesktop)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Form Fields Left Section (with Image Card under Brand)
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: ProductBasicDetailsForm(
                          nameController: nameController,
                          codeController: codeController,
                          shortDescriptionController: shortDescriptionController,
                          longDescriptionController: longDescriptionController,
                          categoryId: state.categoryId,
                          brandId: state.brandId,
                          options: options,
                          fieldErrors: state.fieldErrors,
                          onCategoryChanged: controller.updateCategory,
                          onBrandChanged: controller.updateBrand,
                          imageUploadCard: imageCard,
                        ),
                      ),
                    ),

                  const SizedBox(width: TenantAdminSpacing.xl),

                  // Right Side Cards Section (Channel Availability)
                  SizedBox(
                    width: 340,
                    child: ProductChannelAvailabilityCard(
                      posSellable: state.posSellable,
                      allowOnlineSale: state.allowOnlineSale,
                      onPosSellableChanged: controller.setPosSellable,
                      onAllowOnlineSaleChanged: controller.setAllowOnlineSale,
                    ),
                  ),
                ],
                ),
              )
            else
              // Stacked for Tablet / Mobile
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProductBasicDetailsForm(
                        nameController: nameController,
                        codeController: codeController,
                        shortDescriptionController: shortDescriptionController,
                        longDescriptionController: longDescriptionController,
                        categoryId: state.categoryId,
                        brandId: state.brandId,
                        options: options,
                        fieldErrors: state.fieldErrors,
                        onCategoryChanged: controller.updateCategory,
                        onBrandChanged: controller.updateBrand,
                        imageUploadCard: imageCard,
                      ),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      ProductChannelAvailabilityCard(
                        posSellable: state.posSellable,
                        allowOnlineSale: state.allowOnlineSale,
                        onPosSellableChanged: controller.setPosSellable,
                        onAllowOnlineSaleChanged: controller.setAllowOnlineSale,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
