import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../dashboard/product_dashboard_providers.dart';
import '../providers/tenant_product_providers.dart';
import '../utils/product_api_errors.dart';
import '../utils/product_form_validation.dart';
import 'product_form_fields.dart';
import 'product_status_badge.dart';

class ProductDetailForm extends ConsumerStatefulWidget {
  const ProductDetailForm({
    super.key,
    required this.productId,
    required this.detail,
    required this.fieldsEnabled,
    required this.canSave,
    this.options,
  });

  final String productId;
  final TenantProductDetail detail;
  final bool fieldsEnabled;
  final bool canSave;
  final TenantProductCreateOptions? options;

  @override
  ConsumerState<ProductDetailForm> createState() => _ProductDetailFormState();
}

class _ProductDetailFormState extends ConsumerState<ProductDetailForm> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _onHandController = TextEditingController();
  final _availableStockController = TextEditingController();

  var _trackStock = false;
  String? _categoryId;
  String? _subCategoryId;
  String? _brandId;
  String? _unitId;
  String? _taxId;
  final _selectedOutletIds = <String>{};
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  bool get _useDropdowns => widget.fieldsEnabled && widget.options != null;
  bool get _inputsEnabled => widget.fieldsEnabled && !_submitting;

  @override
  void initState() {
    super.initState();
    _syncFromDetail(widget.detail, widget.options);
  }

  @override
  void didUpdateWidget(covariant ProductDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.productId != widget.detail.productId ||
        oldWidget.options != widget.options) {
      _syncFromDetail(widget.detail, widget.options);
    }
  }

  void _syncFromDetail(
    TenantProductDetail detail,
    TenantProductCreateOptions? options,
  ) {
    _nameController.text = detail.productName;
    _skuController.text = detail.sku;
    _barcodeController.text = detail.barcode ?? '';
    _descriptionController.text = detail.shortDescription ?? '';
    _priceController.text = _formatNumber(detail.sellingPrice);
    _costPriceController.text =
        detail.costPrice == null ? '' : _formatNumber(detail.costPrice!);
    _discountPriceController.text = detail.discountPrice == null
        ? ''
        : _formatNumber(detail.discountPrice!);
    _openingStockController.text = detail.stock?.openingStockQuantity == null
        ? ''
        : _formatNumber(detail.stock!.openingStockQuantity!);
    _lowStockController.text = detail.stock?.minimumStockAlertQuantity == null
        ? ''
        : _formatNumber(detail.stock!.minimumStockAlertQuantity!);
    _onHandController.text =
        detail.stock == null ? '' : _formatNumber(detail.stock!.onHandQuantity);
    _availableStockController.text = detail.stock == null
        ? ''
        : _formatNumber(detail.stock!.availableQuantity);

    _trackStock = detail.trackInventory;
    _categoryId = detail.categoryId;
    _subCategoryId = detail.subCategoryId;
    _brandId = detail.brandId;
    _taxId = detail.taxId;
    _unitId = options == null ? null : unitIdForCode(options, detail.unitType);
    _selectedOutletIds
      ..clear()
      ..addAll(detail.outlets.map((item) => item.outletId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _discountPriceController.dispose();
    _openingStockController.dispose();
    _lowStockController.dispose();
    _onHandController.dispose();
    _availableStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final twoColumns = MediaQuery.sizeOf(context).width >= 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Product details',
                      style: TenantAdminTextStyles.sectionTitle(context),
                    ),
                  ),
                  ProductStatusBadge(status: widget.detail.status),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              _buildSection(
                context,
                title: 'Basic details',
                twoColumns: twoColumns,
                fields: _basicFields(),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              _buildSection(
                context,
                title: 'Price & VAT',
                twoColumns: twoColumns,
                fields: _priceFields(),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              _buildSection(
                context,
                title: 'Stock details',
                twoColumns: twoColumns,
                fields: _stockFields(),
              ),
              if (widget.detail.variants.isNotEmpty) ...[
                const SizedBox(height: TenantAdminSpacing.xl),
                _buildVariantsSection(context),
              ],
            ],
          ),
        ),
        if (widget.canSave) ...[
          const SizedBox(height: TenantAdminSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: TenantAdminPrimaryButton(
              label: _submitting ? 'Saving...' : 'Save Changes',
              loading: _submitting,
              onPressed: _inputsEnabled ? _saveChanges : null,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (_submitting || !widget.canSave) {
      return;
    }

    final options = widget.options;
    if (options == null) {
      return;
    }

    final unitCode = unitCodeForId(options, _unitId);
    final errors = validateProductUpdateForm(
      productName: _nameController.text,
      sku: _skuController.text,
      barcode: _barcodeController.text,
      categoryId: _categoryId,
      unitCode: unitCode,
      sellingPriceText: _priceController.text,
      costPriceText: _costPriceController.text,
      discountPriceText: _discountPriceController.text,
      trackInventory: _trackStock,
      openingStockText: _openingStockController.text,
      minimumStockText: _lowStockController.text,
      selectedOutletIds: _selectedOutletIds,
    );

    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      return;
    }

    final sellingPrice = double.parse(_priceController.text.trim());
    final costPrice = _parseOptionalDecimal(_costPriceController.text);
    final discountPrice = _parseOptionalDecimal(_discountPriceController.text);
    final detail = widget.detail;
    final hasVariants = detail.variants.isNotEmpty;
    final batch = detail.batchDetails;

    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    final request = ProductFormData(
      productName: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      categoryId: _categoryId!,
      subCategoryId: _subCategoryId,
      brandId: _brandId,
      unitType: unitCode!,
      shortDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sellingPrice: sellingPrice,
      taxId: _taxId,
      costPrice: costPrice,
      discountPrice: discountPrice,
      trackInventory: _trackStock,
      openingStockQuantity: _trackStock
          ? double.tryParse(_openingStockController.text.trim())
          : null,
      minimumStockAlertQuantity:
          _trackStock ? double.tryParse(_lowStockController.text.trim()) : null,
      maximumStockQuantity:
          _trackStock ? detail.stock?.maximumStockQuantity : null,
      stockUnit: _trackStock ? unitCode : null,
      outletIds:
          _trackStock ? _selectedOutletIds.toList(growable: false) : const [],
      hasVariants: hasVariants,
      variants: hasVariants
          ? detail.variants
              .map(
                (variant) => ProductVariantFormData(
                  variantName: variant.variantName,
                  sku: variant.sku,
                  barcode: variant.barcode,
                  sellingPrice: variant.sellingPrice,
                  discountPrice: variant.discountPrice,
                  status: variant.status,
                ),
              )
              .toList()
          : const [],
      hasExpiryDate: batch != null,
      batchNumber: batch?.batchNumber,
      manufactureDate: batch?.manufactureDate,
      expiryDate: batch?.expiryDate,
      expiryAlertDays: batch?.expiryAlertDays,
      status: _normalizeStatus(detail.status),
    );

    try {
      await ref.read(updateProductProvider).call(
            productId: widget.productId,
            request: request,
          );

      ref
        ..invalidate(productDetailProvider(widget.productId))
        ..invalidate(productListProvider)
        ..invalidate(productSummaryProvider)
        ..invalidate(productDashboardProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully.')),
      );
      context.go('/tenant-admin/products');
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final fieldErrors = productValidationErrors(error);
      if (fieldErrors.isNotEmpty) {
        setState(() {
          _fieldErrors = fieldErrors;
          _submitting = false;
        });
        return;
      }

      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productSubmitErrorMessage(
              error,
              fallback: 'Failed to update product. Please try again.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product. Please try again.'),
        ),
      );
    }
  }

  double? _parseOptionalDecimal(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.trim());
  }

  String _normalizeStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'INACTIVE') {
      return 'INACTIVE';
    }

    return 'ACTIVE';
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required bool twoColumns,
    required List<Widget> fields,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TenantAdminTextStyles.sectionTitle(context)
              .copyWith(fontSize: 16),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        if (!twoColumns)
          for (final field in fields) ...[
            field,
            const SizedBox(height: TenantAdminSpacing.lg),
          ]
        else
          for (var index = 0; index < fields.length; index += 2) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fields[index]),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                  child: index + 1 < fields.length
                      ? fields[index + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
          ],
      ],
    );
  }

  List<Widget> _basicFields() {
    final options = widget.options;
    final subCategories = options?.subCategoriesForCategory(_categoryId) ?? [];

    return [
      ProductFormTextField(
        label: 'Product name',
        hint: 'Enter product name',
        icon: Icons.inventory_2_outlined,
        controller: _nameController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['productName'],
      ),
      ProductFormTextField(
        label: 'Product code / SKU',
        hint: 'Enter SKU',
        icon: Icons.qr_code_2_outlined,
        controller: _skuController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['sku'],
      ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Category',
              hint: 'Select category',
              icon: Icons.category_outlined,
              value: _categoryId,
              enabled: _inputsEnabled,
              errorText: _fieldErrors['categoryId'],
              items: buildOptionItems(
                options: options!.categories
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No categories available',
              ),
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                  _subCategoryId = null;
                });
              },
            )
          : ProductReadOnlyField(
              label: 'Category',
              value: widget.detail.categoryName,
              icon: Icons.category_outlined,
            ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Sub Category',
              hint: _categoryId == null
                  ? 'Select a category first'
                  : 'Select sub category',
              icon: Icons.account_tree_outlined,
              value: _subCategoryId,
              enabled: _inputsEnabled && _categoryId != null,
              errorText: _fieldErrors['subCategoryId'],
              items: buildOptionItems(
                options: subCategories
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No sub categories available',
              ),
              onChanged: (value) => setState(() => _subCategoryId = value),
            )
          : ProductReadOnlyField(
              label: 'Sub Category',
              value: _displayLabel(
                _subCategoryId,
                options?.subCategories
                        .map((item) => (id: item.id, label: item.name))
                        .toList() ??
                    const [],
              ),
              icon: Icons.account_tree_outlined,
            ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Brand (optional)',
              hint: 'Select brand',
              icon: Icons.sell_outlined,
              value: _brandId,
              enabled: _inputsEnabled,
              errorText: _fieldErrors['brandId'],
              items: buildOptionItems(
                options: options!.brands
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No brands available',
              ),
              onChanged: (value) => setState(() => _brandId = value),
            )
          : ProductReadOnlyField(
              label: 'Brand (optional)',
              value: _displayLabel(
                _brandId,
                options?.brands
                        .map((item) => (id: item.id, label: item.name))
                        .toList() ??
                    const [],
              ),
              icon: Icons.sell_outlined,
            ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Unit Type',
              hint: 'Select unit type',
              icon: Icons.straighten_outlined,
              value: _unitId,
              enabled: _inputsEnabled,
              errorText: _fieldErrors['unitType'],
              items: buildOptionItems(
                options: options!.units
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No units available',
              ),
              onChanged: (value) => setState(() => _unitId = value),
            )
          : ProductReadOnlyField(
              label: 'Unit Type',
              value: widget.detail.unitType,
              icon: Icons.straighten_outlined,
            ),
      ProductFormTextField(
        label: 'Barcode (optional)',
        hint: 'Enter barcode',
        icon: Icons.barcode_reader,
        controller: _barcodeController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['barcode'],
      ),
      ProductFormTextField(
        label: 'Short description (optional)',
        hint: 'Add a short product description',
        icon: Icons.notes_outlined,
        controller: _descriptionController,
        enabled: _inputsEnabled,
      ),
    ];
  }

  List<Widget> _priceFields() {
    final options = widget.options;

    return [
      ProductFormTextField(
        label: 'Selling price',
        hint: 'Enter selling price',
        icon: Icons.payments_outlined,
        controller: _priceController,
        enabled: _inputsEnabled,
        keyboardType: TextInputType.number,
        errorText: _fieldErrors['sellingPrice'],
      ),
      ProductFormTextField(
        label: 'Cost price (optional)',
        hint: 'Enter cost price',
        icon: Icons.price_change_outlined,
        controller: _costPriceController,
        enabled: _inputsEnabled,
        keyboardType: TextInputType.number,
        errorText: _fieldErrors['costPrice'],
      ),
      ProductFormTextField(
        label: 'Discount price (optional)',
        hint: 'Enter discount price',
        icon: Icons.local_offer_outlined,
        controller: _discountPriceController,
        enabled: _inputsEnabled,
        keyboardType: TextInputType.number,
        errorText: _fieldErrors['discountPrice'],
      ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Tax / VAT',
              hint: 'Select tax',
              icon: Icons.receipt_long_outlined,
              value: _taxId,
              enabled: _inputsEnabled,
              errorText: _fieldErrors['taxId'],
              items: buildOptionItems(
                options: options!.taxes
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No taxes available',
              ),
              onChanged: (value) => setState(() => _taxId = value),
            )
          : ProductReadOnlyField(
              label: 'Tax / VAT',
              value: widget.detail.taxName ?? '-',
              icon: Icons.receipt_long_outlined,
            ),
    ];
  }

  List<Widget> _stockFields() {
    final options = widget.options;

    return [
      SwitchListTile(
        value: _trackStock,
        onChanged: _inputsEnabled
            ? (value) => setState(() => _trackStock = value)
            : null,
        title: const Text('Track stock for this product'),
        subtitle: const Text('Enable opening stock and low stock alerts.'),
        contentPadding: EdgeInsets.zero,
      ),
      ProductFormTextField(
        label: 'Opening stock',
        hint: '0',
        icon: Icons.inventory_outlined,
        controller: _openingStockController,
        enabled: _inputsEnabled && _trackStock,
        keyboardType: TextInputType.number,
        errorText: _fieldErrors['openingStockQuantity'],
      ),
      ProductFormTextField(
        label: 'Low stock threshold',
        hint: '0',
        icon: Icons.warning_amber_outlined,
        controller: _lowStockController,
        enabled: _inputsEnabled && _trackStock,
        keyboardType: TextInputType.number,
        errorText: _fieldErrors['minimumStockAlertQuantity'],
      ),
      ProductFormTextField(
        label: 'On hand quantity',
        hint: '0',
        icon: Icons.warehouse_outlined,
        controller: _onHandController,
        enabled: false,
        keyboardType: TextInputType.number,
      ),
      ProductFormTextField(
        label: 'Available quantity',
        hint: '0',
        icon: Icons.check_circle_outline,
        controller: _availableStockController,
        enabled: false,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: TenantAdminSpacing.md),
      Text(
        'Assigned outlets',
        style:
            TenantAdminTextStyles.sectionTitle(context).copyWith(fontSize: 16),
      ),
      const SizedBox(height: TenantAdminSpacing.md),
      if (_fieldErrors['outletIds'] != null)
        Padding(
          padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
          child: Text(
            _fieldErrors['outletIds']!,
            style: const TextStyle(
              color: TenantAdminColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      if (_useDropdowns && options!.outlets.isNotEmpty)
        for (final outlet in options.outlets) ...[
          CheckboxListTile(
            value: _selectedOutletIds.contains(outlet.id),
            onChanged: _inputsEnabled
                ? (value) {
                    setState(() {
                      if (value == true) {
                        _selectedOutletIds.add(outlet.id);
                      } else {
                        _selectedOutletIds.remove(outlet.id);
                      }
                    });
                  }
                : null,
            title: Text(
              outlet.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(outlet.code),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ]
      else if (widget.detail.outlets.isEmpty)
        const Text(
          'No outlets assigned.',
          style: TextStyle(color: TenantAdminColors.mutedText),
        )
      else
        for (final outlet in widget.detail.outlets) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              outlet.outletName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${outlet.outletCode} · On hand: ${_formatNumber(outlet.onHandQuantity)}',
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
    ];
  }

  Widget _buildVariantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variants',
          style: TenantAdminTextStyles.sectionTitle(context)
              .copyWith(fontSize: 16),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        for (final variant in widget.detail.variants) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              variant.variantName ?? variant.sku,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'SKU: ${variant.sku} · Price: ${_formatNumber(variant.sellingPrice)}',
            ),
            trailing: ProductStatusBadge(status: variant.status),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
      ],
    );
  }

  String _displayLabel(
    String? id,
    List<({String id, String label})> options,
  ) {
    if (id == null) {
      return '-';
    }

    return labelForId(id, options) ?? '-';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}

class ProductReadOnlyField extends StatelessWidget {
  const ProductReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        InputDecorator(
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 19),
            filled: true,
            fillColor: TenantAdminColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(color: TenantAdminColors.bodyText),
          ),
        ),
      ],
    );
  }
}
