import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../domain/entities/inventory.dart';
import '../config/inventory_api_capabilities.dart';
import '../providers/inventory_providers.dart';
import '../utils/stock_in_form_validator.dart';
import 'inventory_form_widgets.dart';
import 'stock_in_product_select.dart';

class AddStockForm extends ConsumerStatefulWidget {
  const AddStockForm({
    super.key,
    required this.visibility,
    required this.backendErrors,
    required this.submitting,
    required this.onCancel,
    required this.onSave,
    required this.onSubmit,
  });

  final AddStockVisibility visibility;
  final Map<String, String> backendErrors;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Future<bool> Function(StockInFormData data) onSubmit;

  @override
  ConsumerState<AddStockForm> createState() => AddStockFormState();
}

class AddStockFormState extends ConsumerState<AddStockForm> {
  final _quantityController = TextEditingController();
  final _batchController = TextEditingController();
  final _unitCostController = TextEditingController();
  DateTime? _expiryDate;
  Map<String, String> _clientErrors = const {};

  Map<String, String> get _fieldErrors => {
        ...widget.backendErrors,
        ..._clientErrors,
      };

  @override
  void didUpdateWidget(covariant AddStockForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backendErrors != widget.backendErrors &&
        widget.backendErrors.isNotEmpty) {
      _clientErrors = const {};
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _batchController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  void _onProductSelected(StockProductOption? product) {
    if (product == null) {
      ref.read(stockInSelectedVariantIdProvider.notifier).state = null;
      return;
    }

    if (product.variants.length == 1) {
      ref.read(stockInSelectedVariantIdProvider.notifier).state =
          product.variants.first.variantId;
    } else {
      ref.read(stockInSelectedVariantIdProvider.notifier).state = null;
    }

    setState(() => _clientErrors = const {});
  }

  StockVariantOption? _selectedVariant(
    StockProductOption? product,
    String? selectedVariantId,
  ) {
    if (product == null) {
      return null;
    }

    for (final variant in product.variants) {
      if (variant.variantId == selectedVariantId) {
        return variant;
      }
    }

    if (product.variants.length == 1) {
      return product.variants.first;
    }

    return null;
  }

  String? _quantityUnitSuffix(StockVariantOption? variant, StockProductOption? product) {
    final variantUnit = variant?.unitOfMeasure?.trim();
    if (variantUnit != null && variantUnit.isNotEmpty) {
      return variantUnit;
    }

    return product?.unitOfMeasure;
  }

  Future<bool> submit() async {
    final products = ref.read(stockInProductsProvider).valueOrNull ?? const [];
    final selectedProductId = ref.read(stockInSelectedProductIdProvider);
    final selectedVariantId = ref.read(stockInSelectedVariantIdProvider);
    StockProductOption? selectedProduct;
    for (final product in products) {
      if (product.productId == selectedProductId) {
        selectedProduct = product;
        break;
      }
    }

    final resolvedVariantId = selectedVariantId ??
        ((selectedProduct?.variants.length == 1)
            ? selectedProduct!.variants.first.variantId
            : '');

    final selectedLocationId = ref.read(stockInSelectedLocationIdProvider);

    final data = StockInFormData(
      productId: selectedProductId ?? '',
      variantId: resolvedVariantId,
      inventoryLocationId: selectedLocationId ?? '',
      quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
      unitCost: double.tryParse(_unitCostController.text.trim()),
      batchNumber: _batchController.text.trim(),
      expiryDate: _expiryDate,
      reason: null,
    );

    final errors = StockInFormValidator.validate(
      data: data,
      options: StockInFormValidator.defaultOptions(
        hasVariants: (selectedProduct?.variants.length ?? 0) > 1,
      ),
    );

    if (errors.isNotEmpty) {
      setState(() => _clientErrors = errors);
      return false;
    }

    setState(() => _clientErrors = const {});
    return widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visibility.showForm) {
      return const SizedBox.shrink();
    }

    final productsState = ref.watch(stockInProductsProvider);
    final locationsState = ref.watch(inventoryLocationsProvider);
    final selectedProductId = ref.watch(stockInSelectedProductIdProvider);
    final selectedVariantId = ref.watch(stockInSelectedVariantIdProvider);
    final selectedLocationId = ref.watch(stockInSelectedLocationIdProvider);
    final canEdit = widget.visibility.canEditFields;

    final products = productsState.valueOrNull ?? const <StockProductOption>[];
    StockProductOption? selectedProduct;
    for (final product in products) {
      if (product.productId == selectedProductId) {
        selectedProduct = product;
        break;
      }
    }

    final variants = selectedProduct?.variants ?? const <StockVariantOption>[];
    final selectedVariant = _selectedVariant(selectedProduct, selectedVariantId);
    final quantityUnit = _quantityUnitSuffix(selectedVariant, selectedProduct);
    final hasProductSelected = selectedProductId != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08071A33),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x04071A33),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.visibility.canEditFields)
            const InventoryApiBanner(
              message:
                  'You have view-only access to Stock In. '
                  'The inventory.stock.adjust permission is required to edit and save.',
            ),
          if (!widget.visibility.stockInApiAvailable)
            const InventoryApiBanner(
              message:
                  'Stock-in API is not available yet (POST /api/v1/inventory/stock-movements). '
                  'You can prepare the form, but Save is disabled until the backend endpoint is enabled.',
            ),
          if (!InventoryApiCapabilities.listLocations)
            const InventoryApiBanner(
              message:
                  'Inventory locations API is not available yet (GET /api/v1/inventory/locations). '
                  'Location selection will appear once the backend endpoint is enabled.',
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;

              final rows = <List<Widget>>[
                [
                  _productField(canEdit),
                  _variantField(
                    variants: variants,
                    selectedVariantId: selectedVariantId,
                    hasProductSelected: hasProductSelected,
                    canEdit: canEdit,
                  ),
                ],
                [
                  _locationField(locationsState, selectedLocationId, canEdit),
                  _quantityField(quantityUnit, canEdit),
                ],
                [
                  _batchField(canEdit),
                  _expiryField(canEdit),
                ],
                [
                  _unitCostField(canEdit),
                  if (widget.visibility.showReasonField)
                    _reasonField(canEdit)
                  else
                    const SizedBox.shrink(),
                ],
              ];

              final fields = <Widget>[];
              for (final row in rows) {
                if (isWide) {
                  fields.add(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: row[0]),
                        const SizedBox(width: TenantAdminSpacing.lg),
                        Expanded(child: row[1]),
                      ],
                    ),
                  );
                } else {
                  fields.addAll(row);
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...fields,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  InventoryFormActions(
                    onCancel: widget.onCancel,
                    onSave: widget.onSave,
                    submitting: widget.submitting,
                    saveEnabled: widget.visibility.showSaveButton && canEdit,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _productField(bool canEdit) {
    return InventoryFormField(
      label: 'Product',
      requiredField: true,
      errorText: _fieldErrors['productId'],
      child: widget.visibility.showProductSelect
          ? StockInProductSelect(
              enabled: canEdit,
              errorText: _fieldErrors['productId'],
              onSelected: _onProductSelected,
            )
          : _disabledField(
              hint: 'Product selection unavailable.',
            ),
    );
  }

  Widget _variantField({
    required List<StockVariantOption> variants,
    required String? selectedVariantId,
    required bool hasProductSelected,
    required bool canEdit,
  }) {
    final enabled = canEdit && hasProductSelected && variants.length > 1;
    final resolvedValue = variants.any(
      (item) => item.variantId == selectedVariantId,
    )
        ? selectedVariantId
        : (variants.length == 1 ? variants.first.variantId : null);

    return InventoryFormField(
      label: 'Variant',
      requiredField: variants.length > 1,
      errorText: _fieldErrors['variantId'],
      child: !hasProductSelected
          ? _disabledField(hint: 'Select a product first.')
          : variants.isEmpty
              ? const Text(
                  'No variants found for this product.',
                  style: TextStyle(color: TenantAdminColors.mutedText),
                )
              : DropdownButtonFormField<String>(
                  initialValue: resolvedValue,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select variant',
                  ),
                  items: variants
                      .map(
                        (variant) => DropdownMenuItem(
                          value: variant.variantId,
                          child: Text(variant.label),
                        ),
                      )
                      .toList(),
                  onChanged: enabled
                      ? (value) {
                          ref
                              .read(stockInSelectedVariantIdProvider.notifier)
                              .state = value;
                          setState(() => _clientErrors = const {});
                        }
                      : null,
                ),
    );
  }

  Widget _locationField(
    AsyncValue<List<InventoryLocation>> locationsState,
    String? selectedLocationId,
    bool canEdit,
  ) {
    final locations = locationsState.valueOrNull ?? const <InventoryLocation>[];

    return InventoryFormField(
      label: 'Outlet / Location',
      requiredField: true,
      errorText: _fieldErrors['inventoryLocationId'],
      child: _locationsDropdown(
        loading: locationsState.isLoading,
        error: locationsState.hasError,
        emptyMessage: InventoryApiCapabilities.listLocations
            ? 'No inventory locations found.'
            : 'Locations API not available.',
        value: selectedLocationId,
        items: locations
            .map(
              (location) => DropdownMenuItem(
                value: location.id,
                child: Text(location.name),
              ),
            )
            .toList(),
        enabled: widget.visibility.showLocationSelect &&
            canEdit &&
            locations.isNotEmpty,
        onChanged: (value) {
          ref.read(stockInSelectedLocationIdProvider.notifier).state = value;
          setState(() => _clientErrors = const {});
        },
      ),
    );
  }

  Widget _quantityField(String? unitSuffix, bool canEdit) {
    return InventoryFormField(
      label: 'Quantity',
      requiredField: true,
      errorText: _fieldErrors['quantity'],
      child: TextField(
        controller: _quantityController,
        enabled: canEdit,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffixText: unitSuffix,
        ),
        onChanged: (_) => setState(() => _clientErrors = const {}),
      ),
    );
  }

  Widget _batchField(bool canEdit) {
    return InventoryFormField(
      label: 'Batch Number',
      errorText: _fieldErrors['batchNumber'],
      child: TextField(
        controller: _batchController,
        enabled: canEdit,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() => _clientErrors = const {}),
      ),
    );
  }

  Widget _expiryField(bool canEdit) {
    final label = _expiryDate == null
        ? 'Select expiry date'
        : '${_expiryDate!.day.toString().padLeft(2, '0')}/'
            '${_expiryDate!.month.toString().padLeft(2, '0')}/'
            '${_expiryDate!.year}';

    return InventoryFormField(
      label: 'Expiry Date',
      errorText: _fieldErrors['expiryDate'],
      child: OutlinedButton.icon(
        onPressed: canEdit
            ? () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  setState(() {
                    _expiryDate = picked;
                    _clientErrors = const {};
                  });
                }
              }
            : null,
        icon: const Icon(Icons.calendar_today_outlined, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _unitCostField(bool canEdit) {
    return InventoryFormField(
      label: 'Unit Cost',
      errorText: _fieldErrors['unitCost'],
      child: TextField(
        controller: _unitCostController,
        enabled: canEdit,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixText: 'LKR ',
        ),
        onChanged: (_) => setState(() => _clientErrors = const {}),
      ),
    );
  }

  Widget _reasonField(bool canEdit) {
    return InventoryFormField(
      label: 'Reason',
      errorText: _fieldErrors['reason'],
      child: _disabledField(
        hint: 'Reason options API not available yet.',
        enabled: canEdit && InventoryApiCapabilities.stockInReasons,
      ),
    );
  }

  Widget _disabledField({
    required String hint,
    bool enabled = false,
  }) {
    return TextField(
      enabled: enabled,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hint,
      ),
    );
  }

  Widget _locationsDropdown({
    required bool loading,
    required bool error,
    required String emptyMessage,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    if (loading) {
      return const LinearProgressIndicator();
    }

    if (error || items.isEmpty) {
      return Text(
        emptyMessage,
        style: const TextStyle(color: TenantAdminColors.mutedText),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: items.any((item) => item.value == value) ? value : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Select location',
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }
}
