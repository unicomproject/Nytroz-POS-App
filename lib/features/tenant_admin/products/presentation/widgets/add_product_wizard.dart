import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_wizard_capabilities.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_toast.dart';
import 'add_product_stepper.dart';
import 'product_type_tracking/product_type_tracking.dart';
import 'product_wizard_summary.dart';
import 'basic_details/basic_details.dart';
import 'units_pack_conversion/units_pack_conversion.dart';
import 'variant_configuration/variant_configuration_form.dart';
import 'barcode_sku/barcode_sku_form.dart';
import 'scan_barcode/scan_barcode_step.dart';
import 'pricing_tax/pricing_tax_form.dart';
import 'review_create/product_created_success.dart';
import 'review_create/review_create.dart';
import 'wizard_actions_footer.dart';

class AddProductWizard extends ConsumerStatefulWidget {
  const AddProductWizard({
    super.key,
    required this.options,
    required this.dropdownsEnabled,
    required this.canCreate,
    this.resumeProductId,
    this.resumeLocalDraftId,
    this.duplicateFromProductId,
    this.capabilities,
  });

  final TenantProductCreateOptions options;
  final bool dropdownsEnabled;
  final bool canCreate;
  final String? resumeProductId;
  final String? resumeLocalDraftId;
  final String? duplicateFromProductId;
  final ProductWizardCapabilities? capabilities;

  @override
  ConsumerState<AddProductWizard> createState() => _AddProductWizardState();
}

class _AddProductWizardState extends ConsumerState<AddProductWizard> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _longDescriptionController;
  late final TextEditingController _batchController;
  late final TextEditingController _serialController;
  final GlobalKey<FormState> _step4FormKey = GlobalKey<FormState>();
  ProductCreateSuccessSnapshot? _createSuccess;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _codeController = TextEditingController();
    _shortDescriptionController = TextEditingController();
    _longDescriptionController = TextEditingController();
    _batchController = TextEditingController();
    _serialController = TextEditingController();

    _nameController.addListener(() {
      final controller = ref.read(addProductWizardControllerProvider.notifier);
      if (_nameController.text !=
          ref.read(addProductWizardControllerProvider).productName) {
        controller.updateProductName(_nameController.text);
      }
    });

    _codeController.addListener(() {
      final controller = ref.read(addProductWizardControllerProvider.notifier);
      if (_codeController.text !=
          ref.read(addProductWizardControllerProvider).internalCode) {
        controller.updateInternalCode(_codeController.text);
      }
    });

    _shortDescriptionController.addListener(() {
      final controller = ref.read(addProductWizardControllerProvider.notifier);
      if (_shortDescriptionController.text !=
          ref.read(addProductWizardControllerProvider).shortDescription) {
        controller.updateShortDescription(_shortDescriptionController.text);
      }
    });

    _longDescriptionController.addListener(() {
      final controller = ref.read(addProductWizardControllerProvider.notifier);
      if (_longDescriptionController.text !=
          ref.read(addProductWizardControllerProvider).longDescription) {
        controller.updateLongDescription(_longDescriptionController.text);
      }
    });

    _batchController.addListener(() {
      final controller = ref.read(addProductWizardControllerProvider.notifier);
      if (_batchController.text !=
          ref.read(addProductWizardControllerProvider).initialBatchNumber) {
        controller.updateInitialBatchNumber(_batchController.text);
      }
    });

    _serialController.addListener(() {
      final controller = ref.read(addProductWizardControllerProvider.notifier);
      if (_serialController.text !=
          ref.read(addProductWizardControllerProvider).initialSerialNumber) {
        controller.updateInitialSerialNumber(_serialController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(addProductWizardControllerProvider.notifier);
      if (widget.capabilities != null) {
        controller.bindCapabilities(widget.capabilities!);
      }
      controller.initWizard(
        resumeProductId: widget.resumeProductId,
        resumeLocalDraftId: widget.resumeLocalDraftId,
        duplicateFromProductId: widget.duplicateFromProductId,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _shortDescriptionController.dispose();
    _longDescriptionController.dispose();
    _batchController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _syncControllersWithState() {
    final state = ref.read(addProductWizardControllerProvider);
    if (_nameController.text != state.productName) {
      _nameController.text = state.productName;
    }
    if (_codeController.text != state.internalCode) {
      _codeController.text = state.internalCode;
    }
    if (_shortDescriptionController.text != state.shortDescription) {
      _shortDescriptionController.text = state.shortDescription;
    }
    if (_longDescriptionController.text != state.longDescription) {
      _longDescriptionController.text = state.longDescription;
    }
    if (_batchController.text != state.initialBatchNumber) {
      _batchController.text = state.initialBatchNumber;
    }
    if (_serialController.text != state.initialSerialNumber) {
      _serialController.text = state.initialSerialNumber;
    }
  }

  Future<void> _handleCancel() async {
    final state = ref.read(addProductWizardControllerProvider);
    if (!state.isDirty) {
      if (context.mounted) {
        ref.read(addProductWizardControllerProvider.notifier).discardAutoSave();
        ref.invalidate(addProductWizardControllerProvider);
        context.go('/tenant-admin/products');
      }
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Unsaved Changes?'),
        content: const Text(
          'You have unsaved changes in this wizard. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantAdminColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ref.read(addProductWizardControllerProvider.notifier).discardAutoSave();
      ref.invalidate(addProductWizardControllerProvider);
      context.go('/tenant-admin/products');
    }
  }

  Future<void> _handleAddAnother() async {
    final controller = ref.read(addProductWizardControllerProvider.notifier);
    await controller.startFreshWizard();
    if (!mounted) return;
    _nameController.clear();
    _codeController.clear();
    _shortDescriptionController.clear();
    _longDescriptionController.clear();
    _batchController.clear();
    _serialController.clear();
    setState(() => _createSuccess = null);
    final needsCleanRoute = widget.resumeProductId != null ||
        widget.resumeLocalDraftId != null ||
        widget.duplicateFromProductId != null;
    if (needsCleanRoute) {
      context.go('/tenant-admin/products/add');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductWizardControllerProvider);
    final controller = ref.read(addProductWizardControllerProvider.notifier);
    final createSuccess = _createSuccess;

    ref.listen(addProductWizardControllerProvider, (previous, next) {
      if (previous?.productName != next.productName ||
          previous?.internalCode != next.internalCode ||
          previous?.shortDescription != next.shortDescription ||
          previous?.longDescription != next.longDescription ||
          previous?.initialBatchNumber != next.initialBatchNumber ||
          previous?.initialSerialNumber != next.initialSerialNumber) {
        _syncControllersWithState();
      }
      if (next.pageError != null && next.pageError != previous?.pageError) {
        showAppToast(
          context,
          title: 'Error',
          message: next.pageError!,
          type: AppToastType.error,
        );
      }
    });

    if (createSuccess != null) {
      return ProductCreatedSuccess(
        snapshot: createSuccess,
        onViewProduct: () =>
            context.go('/tenant-admin/products/${createSuccess.productId}'),
        onAddAnother: _handleAddAnother,
        onBackToProducts: () => context.go('/tenant-admin/products'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stepper Component
        AddProductStepper(
          currentStep: state.currentStep,
          onStepTapped: (step) => controller.goToStep(step),
        ),

        const SizedBox(height: TenantAdminSpacing.lg),

        // Content + Conditional Summary Rail
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showSummary = (widget.resumeProductId != null ||
                      widget.resumeLocalDraftId != null) &&
                  state.status.toUpperCase() == 'DRAFT' &&
                  constraints.maxWidth >= 1000;
              // Tip rail only when wide enough so 1024×768 main form is not crushed.
              final showScanTips =
                  state.currentStep == 1 && constraints.maxWidth >= 1180;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                      decoration: BoxDecoration(
                        color: TenantAdminColors.surface,
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.lg),
                        border: Border.all(color: TenantAdminColors.border),
                        boxShadow: TenantAdminShadows.card,
                      ),
                      child: _buildStepContent(state, controller),
                    ),
                  ),
                  if (showScanTips) ...[
                    const SizedBox(width: TenantAdminSpacing.lg),
                    _ScanStepHelpCard(panel: state.scanStepState.panel),
                  ] else if (showSummary) ...[
                    const SizedBox(width: TenantAdminSpacing.lg),
                    ProductWizardSummary(state: state),
                  ],
                ],
              );
            },
          ),
        ),

        const SizedBox(height: TenantAdminSpacing.lg),

        if (state.currentStep > 1)
          WizardActionsFooter(
            onBack: () => controller.goToPreviousApplicableStep(),
            onCancel: _handleCancel,
            onSaveDraft: state.currentStep == 1
                ? null
                : () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    // Small delay to allow focus change handlers to complete their synchronous state updates
                    await Future.delayed(const Duration(milliseconds: 50));
                    final success = await controller.saveDraft();
                    if (success && context.mounted) {
                      ref.invalidate(localProductWizardDraftsProvider);
                      ref.invalidate(productListProvider);
                      // Draft saved toast removed
                      context.go('/tenant-admin/products');
                    }
                  },
            onSkip: controller.canSkipCurrentStep
                ? () async {
                    final success = await controller.skip();
                    if (success && context.mounted) {
                      // Skip toast removed
                    }
                  }
                : null,
            showSkip: controller.canSkipCurrentStep,
            onContinue: state.currentStep == 1
                ? null
                : () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    await Future.delayed(const Duration(milliseconds: 50));
                    final isStep6 = state.currentStep == 6;
                    if (isStep6 && state.isSubmitting) {
                      return;
                    }

                    final success = await controller.saveAndContinue();
                    if (success && context.mounted) {
                      if (isStep6) {
                        ref.invalidate(localProductWizardDraftsProvider);
                        ref.invalidate(productListProvider);
                        ref.invalidate(productSummaryProvider);
                        setState(() {
                          _createSuccess =
                              ProductCreateSuccessSnapshot.fromWizard(
                            ref.read(addProductWizardControllerProvider),
                          );
                        });
                      } else {
                        // Step saved toast removed
                      }
                    }
                  },
            isSavingDraft: state.isSavingDraft,
            isSubmitting: state.isSubmitting,
            continueLabel: state.currentStep == 6 ? 'Create Product' : 'Continue',
            backLabel: 'Back',
          ),
      ],
    );
  }

  Widget _buildStepContent(
    AddProductWizardState state,
    AddProductWizardController controller,
  ) {
    switch (state.currentStep) {
      case 1:
        return ScanBarcodeStep(
          state: state,
          controller: controller,
        );
      case 2:
        return Step1BasicDetails(
          state: state,
          controller: controller,
          nameController: _nameController,
          codeController: _codeController,
          shortDescriptionController: _shortDescriptionController,
          longDescriptionController: _longDescriptionController,
        );
      case 3:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Product Type & Configuration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 680;
                  final cards = [
                    ProductStructureCard(
                      structure: 'SIMPLE',
                      title: 'Simple Product',
                      description: 'Single SKU product with no variants (e.g., T-shirt)',
                      icon: Icons.inventory_2_outlined,
                      selected: state.productStructure == 'SIMPLE' && state.productStructureConfirmed,
                      onSelected: () => controller.setProductStructure('SIMPLE'),
                    ),
                    ProductStructureCard(
                      structure: 'VARIANT',
                      title: 'Variant Product',
                      description: 'Product with multiple options (e.g., T-shirt with size, color)',
                      icon: Icons.dashboard_customize_outlined,
                      selected: state.productStructure == 'VARIANT' && state.productStructureConfirmed,
                      enabled: widget.capabilities?.canManageVariants ?? true,
                      onSelected: () => controller.setProductStructure('VARIANT'),
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cards[0],
                        const SizedBox(height: TenantAdminSpacing.md),
                        cards[1],
                      ],
                    );
                  }

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(child: cards[1]),
                      ],
                    ),
                  );
                },
              ),
              if (state.productStructureConfirmed) ...[
                if (state.productStructure == 'SIMPLE') ...[
                  const SizedBox(height: TenantAdminSpacing.xl),
                  const Divider(),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  // Units
                  UnitsPackConversionForm(
                    state: state,
                    controller: controller,
                  ),
                ],
                
                if (state.productStructure == 'VARIANT') ...[
                  const SizedBox(height: TenantAdminSpacing.xl),
                  Step4VariantConfigurationForm(
                    state: state,
                    controller: controller,
                    formKey: _step4FormKey,
                  ),
                ],

                const SizedBox(height: TenantAdminSpacing.xl),
                const Step5BarcodeSkuForm(),
              ],
            ],
          ),
        );
      case 4:
        return const Step6PricingTaxForm();
      case 5:
        return ProductTypeTracking(
          state: state,
          controller: controller,
          canManageVariants: widget.capabilities?.canManageVariants ?? true,
          canUseAdvancedInventoryTracking:
              widget.capabilities?.canUseAdvancedInventoryTracking ?? true,
          batchController: _batchController,
          serialController: _serialController,
        );
      case 6:
        return Step7ReviewCreate(
          state: state,
          controller: controller,
          canViewProductCost: widget.capabilities?.canViewProductCost ?? true,
        );
      default:
        return ScanBarcodeStep(
          state: state,
          controller: controller,
        );
    }
  }
}

/// Right-rail help card for Step 1 (screenshot family). Shown only when wide.
class _ScanStepHelpCard extends StatelessWidget {
  const _ScanStepHelpCard({required this.panel});

  final ScanBarcodePanel panel;

  @override
  Widget build(BuildContext context) {
    final tip = switch (panel) {
      ScanBarcodePanel.scanReady =>
        'Use a HID barcode scanner, or enter the barcode manually if scanning is unavailable.',
      ScanBarcodePanel.validating =>
        'Format and catalogue checks run automatically after each scan.',
      ScanBarcodePanel.localMatch =>
        'View the existing product, create a duplicate draft, or cancel and rescan.',
      ScanBarcodePanel.noLocalMatch =>
        'Search product data, or continue and enter details yourself.',
      ScanBarcodePanel.externalLookup =>
        'Stay on Step 1 while product data is searched.',
      ScanBarcodePanel.externalFound =>
        'Use this product to prefill Basic Details, or create manually.',
      ScanBarcodePanel.externalNoMatch =>
        'Choose exactly one of the four continuation paths.',
      ScanBarcodePanel.manualEntry =>
        'Use length chips 8 / 12 / 13 / 14 to pad leading zeros when needed.',
      ScanBarcodePanel.invalid =>
        'Invalid barcode is a domain validation result — not a network failure.',
      ScanBarcodePanel.noBarcode =>
        'Own-made, service/fee, and unlabelled products can continue without a GTIN.',
    };

    return Container(
      width: 260,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Scan Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          const Divider(height: 1, color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            tip,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: TenantAdminColors.posHomeAccentOrange,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Step 1 stays on Scan Barcode until a draft is created.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: TenantAdminColors.bodyText,
                    ),
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
