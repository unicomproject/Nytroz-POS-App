import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

import 'product_basic_details_form.dart';
import 'product_image_upload_card.dart';
import 'product_channel_availability_card.dart';
import 'product_initial_tracking_card.dart';

class Step1BasicDetails extends StatelessWidget {
  const Step1BasicDetails({
    super.key,
    required this.state,
    required this.controller,
    required this.nameController,
    required this.codeController,
    required this.shortDescriptionController,
    required this.longDescriptionController,
    required this.batchController,
    required this.serialController,
    this.canUseAdvancedInventoryTracking = true,
  });

  final AddProductWizardState state;
  final AddProductWizardController controller;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController shortDescriptionController;
  final TextEditingController longDescriptionController;
  final TextEditingController batchController;
  final TextEditingController serialController;
  final bool canUseAdvancedInventoryTracking;

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
    final options = state.createOptions;
    if (options == null) {
      return const SizedBox.shrink();
    }

    final form = ProductBasicDetailsForm(
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
    );

    final imageCard = ProductImageUploadCard(
      images: state.productImages,
      onPickImage: _pickImage,
      onSetPrimary: controller.setPrimaryImage,
      onDelete: controller.deleteImage,
    );

    final channelCard = ProductChannelAvailabilityCard(
      posSellable: state.posSellable,
      allowOnlineSale: state.allowOnlineSale,
      onPosSellableChanged: controller.setPosSellable,
      onAllowOnlineSaleChanged: controller.setAllowOnlineSale,
    );

    final trackingCard = canUseAdvancedInventoryTracking
        ? ProductInitialTrackingCard(
            batchController: batchController,
            serialController: serialController,
            expiryDate: state.initialExpiryDate,
            onExpiryChanged: controller.updateInitialExpiryDate,
            enabled: true,
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final heightBounded = constraints.maxHeight.isFinite;
        final splitHalves = width >= TenantAdminBreakpoints.smallTablet;

        Widget body;
        if (splitHalves) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: imageCard),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: trackingCard ?? channelCard),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: trackingCard == null
                        ? const SizedBox.shrink()
                        : channelCard,
                  ),
                ],
              ),
            ],
          );
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              form,
              const SizedBox(height: TenantAdminSpacing.md),
              imageCard,
              if (trackingCard != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                trackingCard,
              ],
              const SizedBox(height: TenantAdminSpacing.md),
              channelCard,
            ],
          );
        }

        final scrollable = SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
          child: body,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.pageError != null) ...[
              _PageErrorBanner(
                message: state.pageError!,
                onDismiss: controller.clearPageError,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            if (heightBounded) Expanded(child: scrollable) else scrollable,
          ],
        );
      },
    );
  }
}

class _PageErrorBanner extends StatelessWidget {
  const _PageErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
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
              message,
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
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
