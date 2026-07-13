import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../dashboard/product_dashboard_providers.dart';
import '../providers/tenant_product_providers.dart';
import '../utils/product_api_errors.dart';
import '../utils/product_form_validation.dart';
import 'product_form_fields.dart';

class AddProductWizard extends ConsumerStatefulWidget {
  const AddProductWizard({
    super.key,
    required this.options,
    required this.dropdownsEnabled,
    required this.canCreate,
  });

  final TenantProductCreateOptions options;
  final bool dropdownsEnabled;
  final bool canCreate;

  @override
  ConsumerState<AddProductWizard> createState() => _AddProductWizardState();
}

class _AddProductWizardState extends ConsumerState<AddProductWizard> {  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _lowStockController = TextEditingController();

  var _stepIndex = 0;
  var _trackStock = false;
  String? _categoryId;
  String? _subCategoryId;
  String? _brandId;
  String? _unitId;
  String? _taxId;
  String? _variantTemplateId;
  final _selectedOutletIds = <String>{};
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  bool get _dropdownsEnabled => widget.dropdownsEnabled && !_submitting;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _openingStockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReview = _stepIndex == 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductStepper(currentStep: _stepIndex),
        const SizedBox(height: TenantAdminSpacing.xl),
        Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: _buildStep(),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        _WizardFooter(
          stepIndex: _stepIndex,
          onBack: _submitting ? null : _back,
          onContinue: isReview
              ? (widget.canCreate && !_submitting ? _saveProduct : null)
              : (_submitting ? null : _continue),
          continueLabel: isReview
              ? _submitting
                  ? 'Saving...'
                  : 'Save Product'
              : 'Continue',
          continueLoading: _submitting && isReview,
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_stepIndex) {
      case 1:
        return _buildPriceStep();
      case 2:
        return _buildStockStep();
      case 3:
        return _buildReviewStep();
      default:
        return _buildBasicStep();
    }
  }

  Widget _buildBasicStep() {
    final subCategories =
        widget.options.subCategoriesForCategory(_categoryId);
    final twoColumns = MediaQuery.sizeOf(context).width >= 720;

    final fields = <Widget>[
      ProductFormTextField(
        label: 'Product name',
        hint: 'Enter product name',
        icon: Icons.inventory_2_outlined,
        controller: _nameController,
        enabled: _dropdownsEnabled,
        errorText: _fieldErrors['productName'],
      ),
      ProductFormTextField(
        label: 'Product code / SKU',
        hint: 'Enter SKU',
        icon: Icons.qr_code_2_outlined,
        controller: _skuController,
        enabled: _dropdownsEnabled,
        errorText: _fieldErrors['sku'],
      ),
      ProductOptionDropdown(
        label: 'Category',
        hint: 'Select category',
        icon: Icons.category_outlined,
        value: _categoryId,
        enabled: _dropdownsEnabled,
        errorText: _fieldErrors['categoryId'],
        items: buildOptionItems(
          options: widget.options.categories
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
      ),
      ProductOptionDropdown(
        label: 'Sub Category',
        hint: _categoryId == null
            ? 'Select a category first'
            : 'Select sub category',
        icon: Icons.account_tree_outlined,
        value: _subCategoryId,
        enabled: _dropdownsEnabled && _categoryId != null,
        errorText: _fieldErrors['subCategoryId'],
        items: buildOptionItems(
          options: subCategories
              .map((item) => (id: item.id, label: item.name))
              .toList(),
          emptyLabel: 'No sub categories available',
        ),
        onChanged: (value) => setState(() => _subCategoryId = value),
      ),
      ProductOptionDropdown(
        label: 'Brand (optional)',
        hint: 'Select brand',
        icon: Icons.sell_outlined,
        value: _brandId,
        enabled: _dropdownsEnabled,
        errorText: _fieldErrors['brandId'],
        items: buildOptionItems(
          options: widget.options.brands
              .map((item) => (id: item.id, label: item.name))
              .toList(),
          emptyLabel: 'No brands available',
        ),
        onChanged: (value) => setState(() => _brandId = value),
      ),
      ProductOptionDropdown(
        label: 'Unit Type',
        hint: 'Select unit type',
        icon: Icons.straighten_outlined,
        value: _unitId,
        enabled: _dropdownsEnabled,
        errorText: _fieldErrors['unitType'],
        items: buildOptionItems(
          options: widget.options.units
              .map((item) => (id: item.id, label: item.name))
              .toList(),
          emptyLabel: 'No units available',
        ),
        onChanged: (value) => setState(() => _unitId = value),
      ),
      ProductFormTextField(
        label: 'Barcode (optional)',
        hint: 'Enter barcode',
        icon: Icons.barcode_reader,
        controller: _barcodeController,
        enabled: _dropdownsEnabled,
        errorText: _fieldErrors['barcode'],
      ),
      ProductOptionDropdown(
        label: 'Variant Type / Templates',
        hint: 'Select variant template',
        icon: Icons.tune_outlined,
        value: _variantTemplateId,
        enabled: _dropdownsEnabled,
        items: buildOptionItems(
          options: widget.options.variantOptionTemplates
              .map((item) => (id: item.id, label: item.name))
              .toList(),
          emptyLabel: 'No variant templates available',
        ),
        onChanged: (value) => setState(() => _variantTemplateId = value),
      ),
      ProductFormTextField(
        label: 'Short description (optional)',
        hint: 'Add a short product description',
        icon: Icons.notes_outlined,
        controller: _descriptionController,
        enabled: _dropdownsEnabled,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic details', style: TenantAdminTextStyles.sectionTitle(context)),
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

  Widget _buildPriceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price & VAT', style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        ProductFormTextField(
          label: 'Selling price',
          hint: 'Enter selling price',
          icon: Icons.payments_outlined,
          controller: _priceController,
          enabled: _dropdownsEnabled,
          keyboardType: TextInputType.number,
          errorText: _fieldErrors['sellingPrice'],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        ProductOptionDropdown(
          label: 'Tax / VAT',
          hint: 'Select tax',
          icon: Icons.receipt_long_outlined,
          value: _taxId,
          enabled: _dropdownsEnabled,
          errorText: _fieldErrors['taxId'],
          items: buildOptionItems(
            options: widget.options.taxes
                .map((item) => (id: item.id, label: item.name))
                .toList(),
            emptyLabel: 'No taxes available',
          ),
          onChanged: (value) => setState(() => _taxId = value),
        ),
      ],
    );
  }

  Widget _buildStockStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stock details', style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        SwitchListTile(
          value: _trackStock,
          onChanged:
              _dropdownsEnabled ? (value) => setState(() => _trackStock = value) : null,
          title: const Text('Track stock for this product'),
          subtitle: const Text('Enable opening stock and low stock alerts.'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ProductFormTextField(
                label: 'Opening stock',
                hint: '0',
                icon: Icons.inventory_outlined,
                controller: _openingStockController,
                enabled: _dropdownsEnabled && _trackStock,
                keyboardType: TextInputType.number,
                errorText: _fieldErrors['openingStockQuantity'],
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: ProductFormTextField(
                label: 'Low stock threshold',
                hint: '0',
                icon: Icons.warning_amber_outlined,
                controller: _lowStockController,
                enabled: _dropdownsEnabled && _trackStock,
                keyboardType: TextInputType.number,
                errorText: _fieldErrors['minimumStockAlertQuantity'],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        Text(
          'Assign Outlets',
          style: TenantAdminTextStyles.sectionTitle(context).copyWith(fontSize: 16),
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
        if (widget.options.outlets.isEmpty)
          const Text(
            'No outlets available.',
            style: TextStyle(color: TenantAdminColors.mutedText),
          )
        else
          for (final outlet in widget.options.outlets) ...[
            CheckboxListTile(
              value: _selectedOutletIds.contains(outlet.id),
              onChanged: _dropdownsEnabled
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
          ],
      ],
    );
  }

  Widget _buildReviewStep() {
    final categoryLabel = labelForId(
      _categoryId,
      widget.options.categories
          .map((item) => (id: item.id, label: item.name))
          .toList(),
    );
    final subCategoryLabel = labelForId(
      _subCategoryId,
      widget.options.subCategoriesForCategory(_categoryId)
          .map((item) => (id: item.id, label: item.name))
          .toList(),
    );
    final brandLabel = labelForId(
      _brandId,
      widget.options.brands.map((item) => (id: item.id, label: item.name)).toList(),
    );
    final unitLabel = labelForId(
      _unitId,
      widget.options.units.map((item) => (id: item.id, label: item.name)).toList(),
    );
    final taxLabel = labelForId(
      _taxId,
      widget.options.taxes.map((item) => (id: item.id, label: item.name)).toList(),
    );
    final variantLabel = labelForId(
      _variantTemplateId,
      widget.options.variantOptionTemplates
          .map((item) => (id: item.id, label: item.name))
          .toList(),
    );
    final outletLabels = widget.options.outlets
        .where((outlet) => _selectedOutletIds.contains(outlet.id))
        .map((outlet) => outlet.name)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review', style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        _ReviewRow(label: 'Product name', value: _nameController.text),
        _ReviewRow(label: 'SKU', value: _skuController.text),
        _ReviewRow(label: 'Category', value: categoryLabel),
        _ReviewRow(label: 'Sub Category', value: subCategoryLabel),
        _ReviewRow(label: 'Brand', value: brandLabel),
        _ReviewRow(label: 'Unit Type', value: unitLabel),
        _ReviewRow(label: 'Variant Template', value: variantLabel),
        _ReviewRow(label: 'Selling price', value: _priceController.text),
        _ReviewRow(label: 'Tax / VAT', value: taxLabel),
        _ReviewRow(label: 'Track stock', value: _trackStock ? 'Yes' : 'No'),
        _ReviewRow(label: 'Assigned outlets', value: outletLabels),
      ],
    );
  }

  String? get _unitCode => unitCodeForId(widget.options, _unitId);

  void _back() {
    if (_stepIndex == 0) {
      context.go('/tenant-admin/products');
      return;
    }

    setState(() => _stepIndex--);
  }

  void _continue() {
    final Map<String, String> errors;
    if (_stepIndex == 0) {
      errors = validateBasicStep(
        productName: _nameController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        categoryId: _categoryId,
        unitCode: _unitCode,
      );
    } else if (_stepIndex == 1) {
      errors = validatePriceStep(sellingPriceText: _priceController.text);
    } else if (_stepIndex == 2) {
      errors = validateStockStep(
        trackInventory: _trackStock,
        openingStockText: _openingStockController.text,
        minimumStockText: _lowStockController.text,
        selectedOutletIds: _selectedOutletIds,
        unitCode: _unitCode,
      );
    } else {
      errors = const {};
    }

    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      return;
    }

    setState(() {
      _fieldErrors = const {};
      if (_stepIndex < 3) {
        _stepIndex++;
      }
    });
  }

  Future<void> _saveProduct() async {
    if (_submitting) {
      return;
    }

    final unitCode = _unitCode;
    final errors = validateProductForm(
      productName: _nameController.text,
      sku: _skuController.text,
      barcode: _barcodeController.text,
      categoryId: _categoryId,
      unitCode: unitCode,
      sellingPriceText: _priceController.text,
      trackInventory: _trackStock,
      openingStockText: _openingStockController.text,
      minimumStockText: _lowStockController.text,
      selectedOutletIds: _selectedOutletIds,
    );

    if (errors.isNotEmpty) {
      final errorStep = productErrorStep(errors) ?? 0;
      setState(() {
        _fieldErrors = errors;
        _stepIndex = errorStep;
      });
      return;
    }

    final sellingPrice = double.parse(_priceController.text.trim());

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
      trackInventory: _trackStock,
      openingStockQuantity: _trackStock
          ? double.tryParse(_openingStockController.text.trim())
          : null,
      minimumStockAlertQuantity: _trackStock
          ? double.tryParse(_lowStockController.text.trim())
          : null,
      stockUnit: _trackStock ? unitCode : null,
      outletIds: _trackStock
          ? _selectedOutletIds.toList(growable: false)
          : const [],
      status: 'ACTIVE',
    );

    try {
      await ref.read(createProductProvider).call(request: request);
      ref
        ..invalidate(productListProvider)
        ..invalidate(productSummaryProvider)
        ..invalidate(productDashboardProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully.')),
      );
      context.go('/tenant-admin/products');
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final fieldErrors = productValidationErrors(error);
      if (fieldErrors.isNotEmpty) {
        final errorStep = productErrorStep(fieldErrors) ?? _stepIndex;
        setState(() {
          _fieldErrors = fieldErrors;
          _stepIndex = errorStep;
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
              fallback: 'Failed to save product. Please try again.',
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
          content: Text('Failed to save product. Please try again.'),
        ),
      );
    }
  }
}

class _ProductStepper extends StatelessWidget {
  const _ProductStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Basic details',
      'Price & VAT',
      'Stock details',
      'Review',
    ];

    return Container(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _StepperItem(
                number: index + 1,
                label: steps[index],
                selected: index == currentStep,
                done: index < currentStep,
              ),
            ),
            if (index != steps.length - 1)
              Container(
                width: 34,
                height: 2,
                color: index < currentStep
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _StepperItem extends StatelessWidget {
  const _StepperItem({
    required this.number,
    required this.label,
    required this.selected,
    required this.done,
  });

  final int number;
  final String label;
  final bool selected;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = selected || done
        ? TenantAdminColors.primary
        : TenantAdminColors.mutedText;

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
              selected || done ? TenantAdminColors.primary : TenantAdminColors.background,
          child: Text(
            '$number',
            style: TextStyle(
              color: selected || done ? Colors.white : TenantAdminColors.mutedText,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.stepIndex,
    required this.onBack,
    required this.onContinue,
    required this.continueLabel,
    this.continueLoading = false,
  });

  final int stepIndex;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool continueLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TenantAdminSecondaryButton(
          label: stepIndex == 0 ? 'Cancel' : 'Back',
          onPressed: onBack,
        ),
        const Spacer(),
        TenantAdminPrimaryButton(
          label: continueLabel,
          loading: continueLoading,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value!.trim().isEmpty) ? '-' : value!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
