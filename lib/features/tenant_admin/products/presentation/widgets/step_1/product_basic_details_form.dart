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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final isTwoColumn = width >= TenantAdminBreakpoints.smallTablet;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isTwoColumn) ...[
                _twoColRow(_buildNameField(), _buildCodeField()),
                const SizedBox(height: TenantAdminSpacing.md),
                _twoColRow(_buildCategoryDropdown(), _buildBrandDropdown()),
                const SizedBox(height: TenantAdminSpacing.md),
                _buildReturnPolicyDropdown(),
              ] else ...[
                _buildNameField(),
                const SizedBox(height: TenantAdminSpacing.md),
                _buildCodeField(),
                const SizedBox(height: TenantAdminSpacing.md),
                _buildCategoryDropdown(),
                const SizedBox(height: TenantAdminSpacing.md),
                _buildBrandDropdown(),
                const SizedBox(height: TenantAdminSpacing.md),
                _buildReturnPolicyDropdown(),
              ],
              const SizedBox(height: TenantAdminSpacing.md),
              _buildShortDescriptionField(),
              const SizedBox(height: TenantAdminSpacing.md),
              _buildLongDescriptionField(),
            ],
          );
        },
      ),
    );
  }

  Widget _twoColRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(child: right),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductFormTextField(
          label: 'Product Code *',
          hint: 'AQF-BTL-001',
          icon: Icons.qr_code_2_outlined,
          controller: codeController,
          errorText: fieldErrors['productCode'],
        ),
        const SizedBox(height: 4),
        const Text(
          'SKU will be generated in a later step.',
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildReturnPolicyDropdown() {
    return ProductOptionDropdown(
      label: 'Return Policy *',
      hint: 'Select return policy',
      icon: Icons.assignment_return_outlined,
      value: 'Standard 14-day return',
      items: const [
        DropdownMenuItem(
          value: 'Standard 14-day return',
          child: Text('Standard 14-day return'),
        ),
      ],
      onChanged: (val) {},
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
      label: 'Short Description *',
      hint: 'Brief summary for POS grid',
      icon: Icons.notes_outlined,
      controller: shortDescriptionController,
      maxLines: 2,
      maxLength: 255,
      errorText: fieldErrors['shortDescription'],
    );
  }

  Widget _buildLongDescriptionField() {
    return ProductFormTextField(
      label: 'Long Description (Optional)',
      hint: 'Detailed product features, materials...',
      icon: Icons.description_outlined,
      controller: longDescriptionController,
      maxLines: 3,
      maxLength: 2000,
      errorText: fieldErrors['longDescription'],
    );
  }
}
