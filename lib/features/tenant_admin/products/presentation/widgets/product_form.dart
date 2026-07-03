import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/product.dart';
import '../config/product_api_capabilities.dart';
import '../utils/product_api_errors.dart';
import 'product_expiry_section.dart';
import 'product_image_section.dart';
import 'product_section_card.dart';
import 'product_status_section.dart';
import 'product_variant_section.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({
    super.key,
    required this.visibility,
    required this.backendErrors,
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
    required this.onSave,
  });

  final AddProductFormVisibility visibility;
  final Map<String, String> backendErrors;
  final bool submitting;
  final Future<bool> Function(ProductFormData data) onSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  State<ProductForm> createState() => ProductFormState();
}

class ProductFormState extends State<ProductForm> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  bool _trackStock = false;
  ProductImageDraft? _imageDraft;
  Map<String, String> _clientErrors = const {};

  Map<String, String> get _fieldErrors => {
        ...widget.backendErrors,
        ..._clientErrors,
      };

  @override
  void didUpdateWidget(covariant ProductForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backendErrors != widget.backendErrors &&
        widget.backendErrors.isNotEmpty) {
      _clientErrors = const {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _discountPriceController.dispose();
    super.dispose();
  }

  ProductImageDraft? get imageDraft => _imageDraft;

  Map<String, String> _validateForm() {
    final errors = <String, String>{};

    if (_nameController.text.trim().isEmpty) {
      errors['name'] = 'Product name is required.';
    }

    if (_skuController.text.trim().isEmpty) {
      errors['sku'] = 'SKU is required.';
    }

    final priceText = _sellingPriceController.text.trim();
    if (priceText.isEmpty) {
      errors['sellingPrice'] = 'Selling price is required.';
    } else {
      final price = double.tryParse(priceText);
      if (price == null || price < 0) {
        errors['sellingPrice'] = 'Enter a valid selling price.';
      }
    }

    return errors;
  }

  void _clearFieldError(String field) {
    if (!_clientErrors.containsKey(field)) {
      return;
    }

    setState(() {
      final next = Map<String, String>.from(_clientErrors);
      next.remove(field);
      _clientErrors = next;
    });
  }

  Future<bool> submit() async {
    final clientErrors = _validateForm();
    if (clientErrors.isNotEmpty) {
      setState(() => _clientErrors = clientErrors);
      return false;
    }

    if (_clientErrors.isNotEmpty) {
      setState(() => _clientErrors = const {});
    }

    final sellingPrice = double.tryParse(_sellingPriceController.text.trim());

    return widget.onSubmit(
      ProductFormData(
        name: _nameController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        categoryName: _categoryController.text,
        brandName: _brandController.text,
        description: _descriptionController.text,
        sellingPrice: sellingPrice,
        trackStock: _trackStock,
      ),
    );
  }

  double? get _previewPrice =>
      double.tryParse(_sellingPriceController.text.trim());

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final cardWidth = isMobile
            ? double.infinity
            : (constraints.maxWidth - (2 * TenantAdminSpacing.lg)) / 3;

        Widget sized(Widget child) => SizedBox(width: cardWidth, child: child);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: TenantAdminSpacing.lg,
              runSpacing: TenantAdminSpacing.lg,
              children: [
                if (widget.visibility.showBasicDetails)
                  sized(_BasicDetailsSection(
                    nameController: _nameController,
                    skuController: _skuController,
                    barcodeController: _barcodeController,
                    categoryController: _categoryController,
                    subCategoryController: _subCategoryController,
                    brandController: _brandController,
                    descriptionController: _descriptionController,
                    fieldErrors: _fieldErrors,
                    onFieldChanged: _clearFieldError,
                  )),
                if (widget.visibility.showImageSection)
                  sized(
                    ProductImageSection(
                      enabled: widget.visibility.showImageSection,
                      onImageChanged: (draft) =>
                          setState(() => _imageDraft = draft),
                    ),
                  ),
                if (widget.visibility.showPricingSection)
                  sized(_PricingSection(
                    costPriceController: _costPriceController,
                    sellingPriceController: _sellingPriceController,
                    discountPriceController: _discountPriceController,
                    previewPrice: _previewPrice,
                    fieldErrors: _fieldErrors,
                    onPriceChanged: () => setState(() {}),
                    onFieldChanged: _clearFieldError,
                  )),
                if (widget.visibility.showInventorySection)
                  sized(_InventorySection(
                    trackStock: _trackStock,
                    onTrackStockChanged: (value) =>
                        setState(() => _trackStock = value),
                  )),
                if (widget.visibility.showVariantSection)
                  sized(
                    ProductVariantSection(
                      enabled: widget.visibility.showVariantSection,
                    ),
                  ),
                if (widget.visibility.showExpirySection)
                  sized(
                    ProductExpirySection(
                      enabled: widget.visibility.showExpirySection,
                    ),
                  ),
              ],
            ),
            if (widget.visibility.showStatusSection) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              const ProductStatusSection(),
            ],
            if (_imageDraft != null) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                'Selected image will be uploaded when you save the product.',
                style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ProductFormHeaderActions extends StatelessWidget {
  const ProductFormHeaderActions({
    super.key,
    required this.visibility,
    required this.submitting,
    required this.onCancel,
    required this.onSave,
  });

  final AddProductFormVisibility visibility;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        TenantAdminSecondaryButton(
          label: 'Cancel',
          onPressed: submitting ? null : onCancel,
        ),
        if (visibility.showSaveDraft)
          const TenantAdminSecondaryButton(
            label: 'Save as Draft',
            onPressed: null,
          ),
        if (visibility.showSaveProduct)
          TenantAdminPrimaryButton(
            label: 'Save Product',
            icon: Icons.save_outlined,
            loading: submitting,
            onPressed: submitting ? null : () => onSave(),
          ),
      ],
    );
  }
}

class _BasicDetailsSection extends StatelessWidget {
  const _BasicDetailsSection({
    required this.nameController,
    required this.skuController,
    required this.barcodeController,
    required this.categoryController,
    required this.subCategoryController,
    required this.brandController,
    required this.descriptionController,
    required this.fieldErrors,
    required this.onFieldChanged,
  });

  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController barcodeController;
  final TextEditingController categoryController;
  final TextEditingController subCategoryController;
  final TextEditingController brandController;
  final TextEditingController descriptionController;
  final Map<String, String> fieldErrors;
  final ValueChanged<String> onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Basic Product Details',
      child: Column(
        children: [
          _ProductTextField(
            controller: nameController,
            label: 'Product Name *',
            errorText: fieldErrors['name'],
            onChanged: onFieldChanged,
            fieldKey: 'name',
          ),
          _ProductTextField(
            controller: skuController,
            label: 'Product Code / SKU *',
            errorText: fieldErrors['sku'],
            onChanged: onFieldChanged,
            fieldKey: 'sku',
          ),
          _ProductTextField(
            controller: barcodeController,
            label: 'Barcode',
            suffixIcon: Icons.qr_code_scanner,
            errorText: fieldErrors['barcode'],
            onChanged: onFieldChanged,
            fieldKey: 'barcode',
          ),
          _ProductTextField(
            controller: categoryController,
            label: 'Category (optional)',
            helperText: 'Enter an existing category name from your catalog.',
            errorText: fieldErrors['categoryName'],
            onChanged: onFieldChanged,
            fieldKey: 'categoryName',
          ),
          _ProductTextField(
            controller: subCategoryController,
            label: 'Sub Category (optional)',
            enabled: false,
            helperText: 'Sub category API is not available yet.',
          ),
          _ProductTextField(
            controller: brandController,
            label: 'Brand (optional)',
            errorText: fieldErrors['brandName'],
          ),
          _ProductTextField(
            controller: descriptionController,
            label: 'Product Description (optional)',
            maxLines: 4,
            errorText: fieldErrors['description'],
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({
    required this.costPriceController,
    required this.sellingPriceController,
    required this.discountPriceController,
    required this.previewPrice,
    required this.fieldErrors,
    required this.onPriceChanged,
    required this.onFieldChanged,
  });

  final TextEditingController costPriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController discountPriceController;
  final double? previewPrice;
  final Map<String, String> fieldErrors;
  final VoidCallback onPriceChanged;
  final ValueChanged<String> onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Pricing Details',
      child: Column(
        children: [
          _ProductTextField(
            controller: costPriceController,
            label: 'Cost Price',
            prefixText: 'LKR ',
            enabled: false,
            helperText: 'Cost price API is not available yet.',
          ),
          _ProductTextField(
            controller: sellingPriceController,
            label: 'Selling Price *',
            prefixText: 'LKR ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: fieldErrors['sellingPrice'],
            onChanged: (value) {
              onFieldChanged('sellingPrice');
              onPriceChanged();
            },
            fieldKey: 'sellingPrice',
          ),
          _ProductTextField(
            controller: discountPriceController,
            label: 'Discount Price (optional)',
            prefixText: 'LKR ',
            enabled: false,
            helperText: 'Discount price API is not available yet.',
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Final Price Preview',
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  formatProductPrice(previewPrice),
                  style: const TextStyle(
                    color: Color(0xFF067647),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({
    required this.trackStock,
    required this.onTrackStockChanged,
  });

  final bool trackStock;
  final ValueChanged<bool> onTrackStockChanged;

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Inventory / Stock Details',
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Track Inventory'),
        subtitle: ProductApiCapabilities.openingStockOnCreate
            ? null
            : const Text(
                'Only track inventory is saved today. Opening stock and outlet '
                'assignment are not available yet.',
              ),
        value: trackStock,
        onChanged: onTrackStockChanged,
      ),
    );
  }
}

class _ProductTextField extends StatelessWidget {
  const _ProductTextField({
    required this.controller,
    required this.label,
    this.errorText,
    this.helperText,
    this.prefixText,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.fieldKey,
    this.suffixIcon,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? helperText;
  final String? prefixText;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? fieldKey;
  final IconData? suffixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (value) => onChanged?.call(fieldKey ?? label),
        inputFormatters: keyboardType == const TextInputType.numberWithOptions(
              decimal: true,
            )
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          errorText: errorText,
          prefixText: prefixText,
          suffixIcon:
              suffixIcon == null ? null : Icon(suffixIcon, size: 20),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
