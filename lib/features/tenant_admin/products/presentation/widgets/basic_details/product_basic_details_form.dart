import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_form_fields.dart';

import '../../../../brands/domain/entities/brand.dart';
import 'quick_add_brand_drawer.dart';

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
    this.categoryResolution,
    this.brandResolution,
    this.onBrandCreated,
  });

  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController shortDescriptionController;
  final TextEditingController longDescriptionController;

  final String? categoryId;
  final String? brandId;
  final TenantProductCreateOptions options;
  final Map<String, String> fieldErrors;
  final TenantCategoryResolutionDto? categoryResolution;
  final TenantBrandResolutionDto? brandResolution;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onBrandChanged;

  /// Called with the newly created Brand after a successful Quick Add. Omit
  /// to hide the Quick Add control entirely (e.g. contexts without wizard
  /// state to update).
  final ValueChanged<Brand>? onBrandCreated;

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
    return ProductFormTextField(
      label: 'Product Code *',
      hint: 'AQF-BTL-001',
      icon: Icons.qr_code_2_outlined,
      controller: codeController,
      errorText: fieldErrors['productCode'],
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

  List<TenantCategoryCandidateDto> get _validSuggestions {
    final res = categoryResolution;
    if (res == null || res.mappedCategory != null || res.suggestions.isEmpty) {
      return const [];
    }
    final validCategoryIds = options.categories.map((c) => c.id).toSet();
    return res.suggestions
        .where((s) => validCategoryIds.contains(s.id))
        .take(3)
        .toList();
  }

  Widget _buildCategoryDropdown() {
    final dropdown = ProductOptionDropdown(
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

    final suggestions = _validSuggestions;
    if (suggestions.isEmpty) {
      return dropdown;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        dropdown,
        _buildCategorySuggestions(suggestions),
      ],
    );
  }

  Widget _buildCategorySuggestions(List<TenantCategoryCandidateDto> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(top: TenantAdminSpacing.xs + 2),
      child: Wrap(
        spacing: TenantAdminSpacing.sm,
        runSpacing: TenantAdminSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Suggested:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          ),
          for (final candidate in suggestions) ...[
            InkWell(
              key: Key('category_suggestion_${candidate.id}'),
              onTap: () => onCategoryChanged(candidate.id),
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: categoryId == candidate.id
                      ? TenantAdminColors.secondary
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  border: Border.all(
                    color: categoryId == candidate.id
                        ? TenantAdminColors.primary
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (categoryId == candidate.id) ...[
                      const Icon(Icons.check, size: 14, color: TenantAdminColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      candidate.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: categoryId == candidate.id
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: categoryId == candidate.id
                            ? TenantAdminColors.primary
                            : TenantAdminColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<TenantBrandCandidateDto> get _validBrandSuggestions {
    final res = brandResolution;
    if (res == null || res.mappedBrand != null || res.suggestions.isEmpty) {
      return const [];
    }
    final validBrandIds = options.brands.map((b) => b.id).toSet();
    return res.suggestions
        .where((s) => validBrandIds.contains(s.id))
        .take(3)
        .toList();
  }

  Widget _buildBrandDropdown() {
    final dropdown = ProductOptionDropdown(
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

    final quickAddCallback = onBrandCreated;
    final row = quickAddCallback == null
        ? dropdown
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: dropdown),
              const SizedBox(width: TenantAdminSpacing.xs),
              Consumer(
                builder: (context, ref, _) {
                  final canCreateBrand = ref
                      .watch(tenantAdminAccessCheckerProvider)
                      .maybeWhen(
                        data: (access) => access.canCreateBrand(),
                        orElse: () => false,
                      );
                  if (!canCreateBrand) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    key: const Key('quick_add_brand_button'),
                    tooltip: 'Add Brand',
                    onPressed: () => openQuickAddBrandDrawer(
                      context,
                      prefillName: brandResolution?.externalBrandName,
                      onCreated: quickAddCallback,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    style: IconButton.styleFrom(
                      backgroundColor: TenantAdminColors.subtleBackground,
                      foregroundColor: TenantAdminColors.primary,
                    ),
                  );
                },
              ),
            ],
          );

    final suggestions = _validBrandSuggestions;
    if (suggestions.isEmpty) {
      return row;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        _buildBrandSuggestions(suggestions),
      ],
    );
  }

  Widget _buildBrandSuggestions(List<TenantBrandCandidateDto> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(top: TenantAdminSpacing.xs + 2),
      child: Wrap(
        spacing: TenantAdminSpacing.sm,
        runSpacing: TenantAdminSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Suggested:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          ),
          for (final candidate in suggestions) ...[
            InkWell(
              key: Key('brand_suggestion_${candidate.id}'),
              onTap: () => onBrandChanged(candidate.id),
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: brandId == candidate.id
                      ? TenantAdminColors.secondary
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  border: Border.all(
                    color: brandId == candidate.id
                        ? TenantAdminColors.primary
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (brandId == candidate.id) ...[
                      const Icon(Icons.check, size: 14, color: TenantAdminColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      candidate.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: brandId == candidate.id
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: brandId == candidate.id
                            ? TenantAdminColors.primary
                            : TenantAdminColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
