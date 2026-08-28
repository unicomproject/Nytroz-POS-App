import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_wizard_capabilities.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_toast.dart';
import 'add_product_stepper.dart';
import 'product_type_tracking.dart';
import 'product_wizard_summary.dart';
import 'step_1/step_1_basic_details.dart';
import 'step_3/units_pack_conversion.dart';
import 'step_4/step_4_variant_configuration_form.dart';
import 'step_5/step_5_barcode_sku_form.dart';
import 'step_6/step_6_pricing_tax_form.dart';
import 'step_7/step_7_review_create.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductWizardControllerProvider);
    final controller = ref.read(addProductWizardControllerProvider.notifier);

    ref.listen(addProductWizardControllerProvider, (previous, next) {
      if (previous?.productName != next.productName ||
          previous?.internalCode != next.internalCode ||
          previous?.shortDescription != next.shortDescription ||
          previous?.longDescription != next.longDescription) {
        _syncControllersWithState();
      }
      if (next.pageError != null && next.pageError != previous?.pageError) {
        showAppToast(
          context,
          title: 'Validation Error',
          message: next.pageError!,
          type: AppToastType.error,
        );
      }
    });

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
              final showSummary =
                  (widget.resumeProductId != null ||
                      widget.resumeLocalDraftId != null) &&
                  state.status.toUpperCase() == 'DRAFT' &&
                  constraints.maxWidth >= 1000;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (showSummary) ...[
                    const SizedBox(width: TenantAdminSpacing.lg),
                    ProductWizardSummary(state: state),
                  ],
                ],
              );
            },
          ),
        ),

        const SizedBox(height: TenantAdminSpacing.lg),

        // Wizard Bottom Actions Footer (authoritative shared CTAs)
        WizardActionsFooter(
          onBack: state.currentStep > 1
              ? () => controller.goToPreviousApplicableStep()
              : null,
          onCancel: _handleCancel,
          onSaveDraft: () async {
            final success = await controller.saveDraft();
            if (success && context.mounted) {
              ref.invalidate(localProductWizardDraftsProvider);
              ref.invalidate(productListProvider);
              showProductSaveToast(
                context,
                title: 'Draft Saved',
                message: 'Draft saved locally on this device',
              );
              context.go('/tenant-admin/products');
            }
          },
          onSkip: controller.canSkipCurrentStep
              ? () async {
                  final success = await controller.skip();
                  if (success && context.mounted) {
                    showProductSaveToast(
                      context,
                      title: 'Step Skipped',
                      message: 'Moved to the next step.',
                    );
                  }
                }
              : null,
          showSkip: state.currentStep >= 2 && state.currentStep <= 5,
          onSaveAndContinue: () async {
            final isStep7 = state.currentStep == 7;
            if (isStep7 && state.isSubmitting) {
              return;
            }
            final success = await controller.saveAndContinue();
            if (success && context.mounted) {
              if (isStep7) {
                ref.invalidate(localProductWizardDraftsProvider);
                ref.invalidate(productListProvider);
                ref.invalidate(productSummaryProvider);
                showProductSaveToast(
                  context,
                  title: 'Product Created',
                  message: 'Product created successfully',
                );
                context.go('/tenant-admin/products');
              } else {
                showProductSaveToast(
                  context,
                  title: 'Step Saved',
                  message: 'Progress saved. Continue to the next step.',
                );
              }
            }
          },
          isSavingDraft: state.isSavingDraft,
          isSubmitting: state.isSubmitting,
          saveAndContinueLabel:
              state.currentStep == 7 ? 'Create Product' : 'Save & Continue',
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
        return Step1BasicDetails(
          state: state,
          controller: controller,
          nameController: _nameController,
          codeController: _codeController,
          shortDescriptionController: _shortDescriptionController,
          longDescriptionController: _longDescriptionController,
          batchController: _batchController,
          serialController: _serialController,
        );
      case 2:
        return ProductTypeTracking(
          state: state,
          controller: controller,
        );
      case 3:
        return UnitsPackConversionForm(
          state: state,
          controller: controller,
        );
      case 4:
        switch (state.productStructure.toUpperCase()) {
          case 'VARIANT':
            return Step4VariantConfigurationForm(
              state: state,
              controller: controller,
              formKey: _step4FormKey,
            );
          case 'BUNDLE':
            return _buildStepPlaceholder('Bundle / Kit Composition');
          case 'SIMPLE':
          default:
            return _buildStepPlaceholder('Simple Product Configuration');
        }
      case 5:
        return const Step5BarcodeSkuForm();
      case 6:
        return const Step6PricingTaxForm();
      case 7:
        return Step7ReviewCreate(state: state);
      default:
        return Step1BasicDetails(
          state: state,
          controller: controller,
          nameController: _nameController,
          codeController: _codeController,
          shortDescriptionController: _shortDescriptionController,
          longDescriptionController: _longDescriptionController,
          batchController: _batchController,
          serialController: _serialController,
        );
    }
  }

  Widget _buildStepPlaceholder(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.architecture_outlined,
              size: 48,
              color: TenantAdminColors.posHomeAccentOrange,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            const Text(
              'Review & Create will finalize the product in a later release.',
              style: TextStyle(
                fontSize: 14,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
