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
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  bool _syncingFromState = false;

  String _appliedSku = '';
  String _appliedBarcode = '';
  bool _suppressSimpleFieldSync = false;

  /// VARIANT: uncommitted per-row edits. Status stays Incomplete until Apply.
  final Map<String, String> _variantDraftSkus = {};
  final Map<String, String> _variantDraftBarcodes = {};

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
    setState(() {});
  }

  void _onBarcodeChanged() {
    if (_syncingFromState) return;
    setState(() {});
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
    if (_suppressSimpleFieldSync) return;
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

  void _resetSimpleInputFields() {
    _suppressSimpleFieldSync = true;
    _syncingFromState = true;
    _skuController.clear();
    _barcodeController.clear();
    _syncingFromState = false;
  }

  void _applySimpleIdentifiers(AddProductWizardController controller) {
    _suppressSimpleFieldSync = true;
    controller.updateSimpleBaseSku(_skuController.text);
    controller.updateSimpleParentBarcode(_barcodeController.text);
    if (_skuController.text.trim().isEmpty) {
      controller.generateSimpleIdentifiers(overwriteSku: false);
    }
    final next = ref.read(addProductWizardControllerProvider).step5State;
    if (next.baseSku.trim().isEmpty &&
        next.parentProductBarcode.trim().isEmpty) {
      _suppressSimpleFieldSync = false;
      return;
    }
    controller.commitSimpleBarcodeSkuToState();
    setState(() {
      _appliedSku = next.baseSku;
      _appliedBarcode = next.parentProductBarcode;
    });
    _resetSimpleInputFields();
  }

  void _setVariantDraftSku(String clientCombinationKey, String sku) {
    setState(() => _variantDraftSkus[clientCombinationKey] = sku);
  }

  void _setVariantDraftBarcode(String clientCombinationKey, String barcode) {
    setState(() => _variantDraftBarcodes[clientCombinationKey] = barcode);
  }

  void _applyVariantIdentifierDrafts(
    AddProductWizardController controller,
    AddProductWizardState state,
  ) {
    final selected = state.step5State.selectedClientKeys;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one variant checkbox, enter SKU/Barcode, then Apply.',
          ),
        ),
      );
      return;
    }

    var appliedAny = false;
    for (final key in selected) {
      BarcodeSkuAssignmentDto? assignment;
      for (final a in state.step5State.assignments) {
        if (a.clientCombinationKey == key) {
          assignment = a;
          break;
        }
      }
      if (assignment == null) continue;

      final sku = _variantDraftSkus.containsKey(key)
          ? _variantDraftSkus[key]!
          : (assignment.sku ?? '');
      final barcode = _variantDraftBarcodes.containsKey(key)
          ? _variantDraftBarcodes[key]!
          : (assignment.barcode ?? '');

      controller.updateVariantSku(key, sku);
      controller.updateVariantBarcode(key, barcode);
      appliedAny = true;
      _variantDraftSkus.remove(key);
      _variantDraftBarcodes.remove(key);
    }

    if (!appliedAny) return;

    controller.clearStep5RowSelection();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SKU & barcode applied to selected variants.')),
    );
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

    final siblings = state.step5State.assignments.where(
      (a) => a.clientCombinationKey != assignment.clientCombinationKey,
    );
    final existingBarcodes = siblings
        .map((a) => a.barcode?.trim() ?? '')
        .where((b) => b.isNotEmpty)
        .toSet();
    final existingSkus = siblings
        .map((a) => a.sku?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 460 ? screenWidth : 440.0;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close edit variant SKU & barcode',
      barrierColor: Colors.black54,
      useRootNavigator: false,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));

        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: slide,
            child: Material(
              color: TenantAdminColors.surface,
              elevation: 12,
              child: SizedBox(
                width: drawerWidth,
                height: double.infinity,
                child: EditVariantIdentifierDrawer(
                  variantDto: Step5VariantIdentifierDto(
                    productVariantId: assignment.productVariantId,
                    sku: assignment.sku,
                    barcode: assignment.barcode,
                    barcodeType: assignment.barcodeType,
                  ),
                  displayLabel: label,
                  existingBarcodes: existingBarcodes,
                  existingSkus: existingSkus,
                  onUpdate: (updated) {
                    if (state.productStructure == 'SIMPLE' ||
                        state.productStructure == 'BUNDLE') {
                      controller.updateSimpleBaseSku(updated.sku ?? '');
                      controller.updateSimpleParentBarcode(
                          updated.barcode ?? '');
                      setState(() {
                        _appliedSku = updated.sku ?? '';
                        _appliedBarcode = updated.barcode ?? '';
                      });
                    }
                    controller.updateBarcodeSkuAssignment(
                      BarcodeSkuAssignmentDto(
                        clientCombinationKey: assignment.clientCombinationKey,
                        productVariantId: updated.productVariantId ??
                            assignment.productVariantId,
                        displayName: assignment.displayName,
                        sku: updated.sku,
                        barcode: updated.barcode,
                        barcodeType: updated.barcodeType,
                        isAssigned: (updated.sku?.isNotEmpty ?? false) ||
                            (updated.barcode?.isNotEmpty ?? false),
                      ),
                    );
                  },
                ),
              ),
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
                          onPressed: () => _applySimpleIdentifiers(controller),
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
              onClear: (assignment) =>
                  _confirmAndDeleteAssignment(context, assignment, 0),
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
    final includedVariants =
        state.step4State.generatedVariants.where((v) => v.isIncluded).toList();
    final totalVariants = includedVariants.length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.step5State.assignments.length != totalVariants) {
        controller.ensureVariantStep5Targets();
      }
    });

    final filtered = state.step5State.filteredAssignments;
    final completeCount = state.step5State.completeCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SKU & Barcode — Variant Product',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Assign SKU and barcode to each variant.',
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
        const SizedBox(height: TenantAdminSpacing.sm),
        Step5VariantIdentifierToolbar(
          searchQuery: state.step5State.searchQuery,
          statusFilter: state.step5State.statusFilter,
          completeCount: completeCount,
          totalCount: totalVariants,
          onSearchChanged: controller.setStep5SearchQuery,
          onFilterChanged: controller.setStep5StatusFilter,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Step5IdentifierTable(
            assignments: filtered,
            allVariants: state.step4State.generatedVariants,
            productName: state.productName,
            productStructure: state.productStructure,
            selectedClientKeys: state.step5State.selectedClientKeys,
            inlineEditable: true,
            editOnlyWhenSelected: true,
            draftSkus: _variantDraftSkus,
            draftBarcodes: _variantDraftBarcodes,
            onToggleSelect: controller.toggleStep5RowSelection,
            onSkuChanged: (assignment, sku) =>
                _setVariantDraftSku(assignment.clientCombinationKey, sku),
            onBarcodeChanged: (assignment, barcode) => _setVariantDraftBarcode(
              assignment.clientCombinationKey,
              barcode,
            ),
            onScanComplete: (assignment, barcode) => _setVariantDraftBarcode(
              assignment.clientCombinationKey,
              barcode,
            ),
            onEdit: (assignment, index) =>
                _onEditAssignment(context, assignment, index),
            onClear: (assignment) {
              _variantDraftSkus.remove(assignment.clientCombinationKey);
              _variantDraftBarcodes.remove(assignment.clientCombinationKey);
              controller.clearVariantIdentifierDraft(
                assignment.clientCombinationKey,
              );
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                state.step5State.selectedClientKeys.isEmpty
                    ? 'Select variant checkboxes, enter SKU/Barcode, then Apply.'
                    : 'Apply commits SKU/Barcode for ${state.step5State.selectedClientKeys.length} selected variant(s). Status updates after Apply.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            ElevatedButton(
              onPressed: () =>
                  _applyVariantIdentifierDrafts(controller, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }
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

