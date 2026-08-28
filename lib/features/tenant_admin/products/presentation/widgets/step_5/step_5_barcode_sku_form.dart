import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/tenant_product_providers.dart';
import '../../../data/models/step5_barcode_dtos.dart';
import '../../../domain/entities/add_product_wizard_state.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import '../../controllers/add_product_wizard_controller.dart';
import 'step_5_identifier_table.dart';
import 'edit_variant_identifier_drawer.dart';

class Step5BarcodeSkuForm extends ConsumerStatefulWidget {
  const Step5BarcodeSkuForm({super.key});

  @override
  ConsumerState<Step5BarcodeSkuForm> createState() =>
      _Step5BarcodeSkuFormState();
}

class _Step5BarcodeSkuFormState extends ConsumerState<Step5BarcodeSkuForm> {
  String? _selectedClientKey;

  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  bool _syncingFromState = false;

  String _appliedSku = '';
  String _appliedBarcode = '';

  @override
  void initState() {
    super.initState();
    final state = ref.read(addProductWizardControllerProvider);
    _skuController.text = state.step5State.baseSku;
    _barcodeController.text = state.step5State.parentProductBarcode;
    _appliedSku = state.step5State.baseSku;
    _appliedBarcode = state.step5State.parentProductBarcode;

    _skuController.addListener(_onSkuChanged);
    _barcodeController.addListener(_onBarcodeChanged);
  }

  void _onSkuChanged() {
    if (_syncingFromState) return;
    final structure =
        ref.read(addProductWizardControllerProvider).productStructure;
    if (structure == 'SIMPLE' || structure == 'BUNDLE') {
      ref
          .read(addProductWizardControllerProvider.notifier)
          .updateSimpleBaseSku(_skuController.text);
    }
    // VARIANT: table updates only on Apply button press (_onAssignVariant)
  }

  void _onBarcodeChanged() {
    if (_syncingFromState) return;
    final structure =
        ref.read(addProductWizardControllerProvider).productStructure;
    if (structure == 'SIMPLE' || structure == 'BUNDLE') {
      ref
          .read(addProductWizardControllerProvider.notifier)
          .updateSimpleParentBarcode(_barcodeController.text);
    }
    // VARIANT: table updates only on Apply button press (_onAssignVariant)
  }


  @override
  void dispose() {
    _skuController.removeListener(_onSkuChanged);
    _barcodeController.removeListener(_onBarcodeChanged);
    _skuController.dispose();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _syncSimpleControllersFromState() {
    final state = ref.read(addProductWizardControllerProvider);
    _syncingFromState = true;
    if (_skuController.text != state.step5State.baseSku) {
      _skuController.text = state.step5State.baseSku;
    }
    if (_barcodeController.text != state.step5State.parentProductBarcode) {
      _barcodeController.text = state.step5State.parentProductBarcode;
    }
    _syncingFromState = false;
  }

  List<_VariantDropdownItem> _buildDropdownItems({
    required String productStructure,
    required String productName,
    required List<GeneratedVariantRow> generatedVariants,
  }) {
    final includedVariants =
        generatedVariants.where((v) => v.isIncluded).toList();
    return includedVariants
        .map((v) => _VariantDropdownItem(
              clientKey: v.clientCombinationKey,
              label: v.displayLabel ?? v.combinationLabel,
              productVariantId: v.productVariantId,
            ))
        .toList();
  }

  Future<void> _onAssignVariant() async {
    if (_selectedClientKey == null) return;
    final controller = ref.read(addProductWizardControllerProvider.notifier);

    final sku = _skuController.text.trim();
    final barcode = _barcodeController.text.trim();

    final success = await controller.assignBarcodeSkuAndSave(
      BarcodeSkuAssignmentDto(
        clientCombinationKey: _selectedClientKey!,
        productVariantId: null,
        sku: sku.isEmpty ? null : sku,
        barcode: barcode.isEmpty ? null : barcode,
        isAssigned: sku.isNotEmpty || barcode.isNotEmpty,
      ),
    );

    if (success) {
      setState(() {
        _selectedClientKey = null;
        _skuController.clear();
        _barcodeController.clear();
      });
    }
  }

  void _onEditAssignment(
      BuildContext context, BarcodeSkuAssignmentDto assignment, int index) {
    final state = ref.read(addProductWizardControllerProvider);
    final controller = ref.read(addProductWizardControllerProvider.notifier);

    final variant = state.step4State.generatedVariants.firstWhere(
      (v) => v.clientCombinationKey == assignment.clientCombinationKey,
      orElse: () => const GeneratedVariantRow(
        clientCombinationKey: '',
        combinationLabel: '',
      ),
    );

    final label = variant.clientCombinationKey.isNotEmpty
        ? (variant.displayLabel ?? variant.combinationLabel)
        : (state.productName.isNotEmpty ? state.productName : 'Base Product');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      useRootNavigator: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: EditVariantIdentifierDrawer(
              variantDto: Step5VariantIdentifierDto(
                productVariantId: assignment.productVariantId,
                sku: assignment.sku,
                barcode: assignment.barcode,
              ),
              displayLabel: label,
              onUpdate: (updated) {
                if (state.productStructure == 'SIMPLE' || state.productStructure == 'BUNDLE') {
                  controller.updateSimpleBaseSku(updated.sku ?? '');
                  controller.updateSimpleParentBarcode(updated.barcode ?? '');
                  setState(() {
                    _appliedSku = updated.sku ?? '';
                    _appliedBarcode = updated.barcode ?? '';
                    _skuController.text = _appliedSku;
                    _barcodeController.text = _appliedBarcode;
                  });
                }
                controller.updateBarcodeSkuAssignment(
                  BarcodeSkuAssignmentDto(
                    clientCombinationKey: assignment.clientCombinationKey,
                    productVariantId: updated.productVariantId,
                    sku: updated.sku,
                    barcode: updated.barcode,
                    isAssigned: (updated.sku?.isNotEmpty ?? false) ||
                        (updated.barcode?.isNotEmpty ?? false),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onDeleteAssignment(BarcodeSkuAssignmentDto assignment, int index) {
    final controller = ref.read(addProductWizardControllerProvider.notifier);
    final state = ref.read(addProductWizardControllerProvider);

    if (state.productStructure == 'SIMPLE' || state.productStructure == 'BUNDLE') {
      setState(() {
        _appliedSku = '';
        _appliedBarcode = '';
        _skuController.clear();
        _barcodeController.clear();
      });
      controller.updateSimpleBaseSku('');
      controller.updateSimpleParentBarcode('');
    }

    controller.updateBarcodeSkuAssignment(
      BarcodeSkuAssignmentDto(
        clientCombinationKey: assignment.clientCombinationKey,
        productVariantId: assignment.productVariantId,
        sku: null,
        barcode: null,
        isAssigned: false,
      ),
    );
  }

  Future<void> _confirmAndDeleteAssignment(
      BuildContext context, BarcodeSkuAssignmentDto assignment, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: TenantAdminColors.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.link_off_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.md),
                      const Expanded(
                        child: Text(
                          'Remove Assignment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TenantAdminColors.bodyText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: TenantAdminColors.mutedText,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const Text(
                    'Are you sure you want to remove the SKU and Barcode assignment for this item?',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(TenantAdminSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      border: Border.all(color: TenantAdminColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2,
                          size: 28,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment.sku?.isNotEmpty == true
                                    ? assignment.sku!
                                    : 'No SKU',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: TenantAdminColors.bodyText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Barcode: ${assignment.barcode?.isNotEmpty == true ? assignment.barcode : 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: TenantAdminColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          side: const BorderSide(color: TenantAdminColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.md),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.md),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TenantAdminColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.md),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      _onDeleteAssignment(assignment, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductWizardControllerProvider);
    final controller = ref.read(addProductWizardControllerProvider.notifier);
    final isSimpleOrBundle = state.productStructure == 'SIMPLE' ||
        state.productStructure == 'BUNDLE';

    ref.listen(addProductWizardControllerProvider, (previous, next) {
      if (isSimpleOrBundle &&
          (previous?.step5State.baseSku != next.step5State.baseSku ||
              previous?.step5State.parentProductBarcode !=
                  next.step5State.parentProductBarcode)) {
        _syncSimpleControllersFromState();
      }
    });

    if (isSimpleOrBundle) {
      return _buildSimpleForm(state, controller);
    }
    return _buildVariantForm(state, controller);
  }

  Widget _buildSimpleForm(
    AddProductWizardState state,
    AddProductWizardController controller,
  ) {
    final productName =
        state.productName.isNotEmpty ? state.productName : 'Product';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barcode & SKU',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Assign the Base SKU and Parent Product Barcode for this product.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Product'),
                          const SizedBox(height: 6),
                          InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              suffixIcon: const Icon(Icons.lock_outline,
                                  size: 16, color: Colors.grey),
                            ),
                            child: Text(
                              productName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Base SKU *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _skuController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              hintText: 'Enter Base SKU',
                              errorText: state.fieldErrors['sku'],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Parent Product Barcode'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _barcodeController,
                            focusNode: _barcodeFocusNode,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              hintText: 'Type or scan barcode',
                              errorText: state.fieldErrors['barcode'],
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  size: 20,
                                  color: Color(0xFF1D4ED8),
                                ),
                                tooltip:
                                    'Click then scan with hardware scanner',
                                onPressed: () {
                                  _barcodeFocusNode.requestFocus();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            controller.generateSimpleIdentifiers(overwriteSku: false);
                            _syncSimpleControllersFromState();
                            setState(() {
                              _appliedSku = ref.read(addProductWizardControllerProvider).step5State.baseSku;
                              _appliedBarcode = ref.read(addProductWizardControllerProvider).step5State.parentProductBarcode;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Click Apply to update the assignment table below. '
                  'If left empty, Apply will auto-fill Base SKU from Internal Code.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_appliedSku.isNotEmpty || _appliedBarcode.isNotEmpty) ...[
            const Text(
              'Barcode & SKU Assignment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Step5IdentifierTable(
              assignments: [
                BarcodeSkuAssignmentDto(
                  clientCombinationKey: 'SIMPLE_DEFAULT',
                  productVariantId: null,
                  sku: _appliedSku.isNotEmpty ? _appliedSku : null,
                  barcode: _appliedBarcode.isNotEmpty ? _appliedBarcode : null,
                  isAssigned: true,
                )
              ],
              allVariants: const [],
              productName: productName,
              productStructure: state.productStructure,
              onEdit: (assignment, index) =>
                  _onEditAssignment(context, assignment, index),
              onDelete: (assignment, index) =>
                  _confirmAndDeleteAssignment(context, assignment, index),
            ),
            const SizedBox(height: 80),
          ] else
            const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildVariantForm(
    AddProductWizardState state,
    AddProductWizardController controller,
  ) {
    final productName = state.productName;
    final dropdownItems = _buildDropdownItems(
      productStructure: state.productStructure,
      productName: productName,
      generatedVariants: state.step4State.generatedVariants,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.step5State.assignments.length !=
          state.step4State.generatedVariants.where((v) => v.isIncluded).length) {
        controller.ensureVariantStep5Targets();
      }
    });

    void selectVariant(String key) {
      final existing = state.step5State.assignments.where(
        (a) => a.clientCombinationKey == key,
      );
      setState(() {
        _selectedClientKey = key;
        _syncingFromState = true;
        _skuController.text =
            existing.isNotEmpty ? (existing.first.sku ?? '') : '';
        _barcodeController.text =
            existing.isNotEmpty ? (existing.first.barcode ?? '') : '';
        _syncingFromState = false;
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barcode & SKU',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Assign SKU and barcode identifiers to each generated variant.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          if (state.fieldErrors['skuDuplicate'] != null) ...[
            const SizedBox(height: 8),
            Text(
              state.fieldErrors['skuDuplicate']!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          if (state.fieldErrors['barcodeDuplicate'] != null) ...[
            const SizedBox(height: 8),
            Text(
              state.fieldErrors['barcodeDuplicate']!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign Identifier',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Variant *'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedClientKey,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: dropdownItems
                                .map((item) => DropdownMenuItem<String>(
                                      value: item.clientKey,
                                      child: Text(
                                        item.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) selectVariant(val);
                            },
                            hint: const Text('Select variant'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Base SKU *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _skuController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              hintText: 'Enter SKU',
                              errorText: state.fieldErrors['sku'],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(label: 'Barcode'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _barcodeController,
                            focusNode: _barcodeFocusNode,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              hintText: 'Type or scan barcode',
                              errorText: state.fieldErrors['barcode'],
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  size: 20,
                                  color: Color(0xFF1D4ED8),
                                ),
                                onPressed: () {
                                  _barcodeFocusNode.requestFocus();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ElevatedButton(
                        onPressed:
                            _selectedClientKey != null ? _onAssignVariant : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          disabledBackgroundColor: Colors.grey.shade200,
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final appliedAssignments = state.step5State.assignments
                .where((a) => a.isAssigned)
                .toList();
            final totalVariants = state.step4State.generatedVariants
                .where((v) => v.isIncluded)
                .length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                  'Variant SKU & Barcode Assignment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (appliedAssignments.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: appliedAssignments.length == totalVariants
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${appliedAssignments.length} / $totalVariants applied',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: appliedAssignments.length == totalVariants
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Step5IdentifierTable(
                  assignments: appliedAssignments,
                  allVariants: state.step4State.generatedVariants,
                  productName: productName,
                  productStructure: state.productStructure,
                  onEdit: (assignment, index) =>
                      _onEditAssignment(context, assignment, index),
                  onDelete: (assignment, index) =>
                      _confirmAndDeleteAssignment(context, assignment, index),
                ),
              ],
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _VariantDropdownItem {
  final String clientKey;
  final String label;
  final String? productVariantId;

  const _VariantDropdownItem({
    required this.clientKey,
    required this.label,
    this.productVariantId,
  });
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Color(0xFF374151),
      ),
    );
  }
}

