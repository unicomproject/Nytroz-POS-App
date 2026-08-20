import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_form_fields.dart';

class ProductBasicDetailsForm extends StatelessWidget {
  const ProductBasicDetailsForm({
    super.key,
    required this.nameController,
    required this.codeController,
    required this.shortDescriptionController,
    required this.longDescriptionController,
    required this.categoryId,
    required this.brandId,
    required this.options,
    required this.fieldErrors,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    this.channelAvailabilityCard,
  });

  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController shortDescriptionController;
  final TextEditingController longDescriptionController;

  final String? categoryId;
  final String? brandId;
  final TenantProductCreateOptions options;
  final Map<String, String> fieldErrors;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onBrandChanged;

  final Widget? channelAvailabilityCard;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTwoColumn = width >= TenantAdminBreakpoints.tablet;

    if (!isTwoColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameField(),
          const SizedBox(height: TenantAdminSpacing.md),
          _buildCodeField(),
          const SizedBox(height: TenantAdminSpacing.md),
          _buildCategoryDropdown(),
          const SizedBox(height: TenantAdminSpacing.md),
          _buildBrandDropdown(),
          if (channelAvailabilityCard != null) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            channelAvailabilityCard!,
          ],
          const SizedBox(height: TenantAdminSpacing.md),
          _buildShortDescriptionField(),
          const SizedBox(height: TenantAdminSpacing.md),
          _buildLongDescriptionField(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Form Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameField(),
              const SizedBox(height: TenantAdminSpacing.md),
              _buildCategoryDropdown(),
              const SizedBox(height: TenantAdminSpacing.md),
              _buildShortDescriptionField(),
              const SizedBox(height: TenantAdminSpacing.md),
              _buildLongDescriptionField(),
            ],
          ),
        ),

        const SizedBox(width: TenantAdminSpacing.lg),

        // Right Form Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCodeField(),
              const SizedBox(height: TenantAdminSpacing.md),
              _buildBrandDropdown(),
              if (channelAvailabilityCard != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                channelAvailabilityCard!,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return ProductFormTextField(
      label: 'Product Name *',
      hint: 'e.g. Premium Cotton Crewneck T-Shirt',
      icon: Icons.inventory_2_outlined,
      controller: nameController,
      errorText: fieldErrors['productName'],
    );
  }

  Widget _buildCodeField() {
    return ProductFormTextField(
      label: 'Short Name / Product Code',
      hint: 'e.g. MERCH-TSHIRT-01',
      icon: Icons.qr_code_2_outlined,
      controller: codeController,
      errorText: fieldErrors['productCode'],
    );
  }

  Widget _buildCategoryDropdown() {
    return ProductOptionDropdown(
      label: 'Category *',
      hint: 'Select category',
      icon: Icons.category_outlined,
      value: categoryId,
      errorText: fieldErrors['categoryId'],
      items: buildOptionItems(
        options: options.categories
            .map((item) => (id: item.id, label: item.name))
            .toList(),
        emptyLabel: 'No categories available',
      ),
      onChanged: onCategoryChanged,
    );
  }

  Widget _buildBrandDropdown() {
    return ProductOptionDropdown(
      label: 'Brand (Optional)',
      hint: 'Select brand (optional)',
      icon: Icons.sell_outlined,
      value: brandId,
      errorText: fieldErrors['brandId'],
      items: buildOptionItems(
        options: options.brands
            .map((item) => (id: item.id, label: item.name))
            .toList(),
        emptyLabel: 'No brands available',
      ),
      onChanged: onBrandChanged,
    );
  }

  Widget _buildShortDescriptionField() {
    return ProductFormTextField(
      label: 'Short Description',
      hint: 'Brief summary for POS grid (e.g. 100% Cotton Crewneck T-Shirt)',
      icon: Icons.notes_outlined,
      controller: shortDescriptionController,
      maxLines: 2,
      errorText: fieldErrors['shortDescription'],
    );
  }

  Widget _buildLongDescriptionField() {
    return ProductFormTextField(
      label: 'Long Description',
      hint:
          'Detailed product features, materials, and care instructions for online store...',
      icon: Icons.description_outlined,
      controller: longDescriptionController,
      maxLines: 4,
      errorText: fieldErrors['longDescription'],
    );
  }
}
