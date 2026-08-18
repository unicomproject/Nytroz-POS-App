import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../data/models/product_draft_response_dto.dart';
import '../../data/models/step5_barcode_dtos.dart';
import '../../data/mappers/wizard_product_create_mapper.dart';
import '../../domain/entities/add_product_wizard_state.dart';
import '../../domain/entities/product_wizard_draft.dart';
import '../../domain/entities/staged_product_image.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/step4_variant_configuration_state.dart';
import '../../domain/utils/variant_combination_generator.dart';
import '../../domain/repositories/product_wizard_draft_local_repository.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class AddProductWizardController extends StateNotifier<AddProductWizardState> {
  AddProductWizardController(
    this._repository, {
    ProductWizardDraftLocalRepository? draftLocal,
  })  : _draftLocal = draftLocal,
        super(const AddProductWizardState());

  final TenantProductRepository _repository;
  final ProductWizardDraftLocalRepository? _draftLocal;

  @visibleForTesting
  AddProductWizardState get wizardState => state;

  @visibleForTesting
  void initializeOptions(TenantProductCreateOptions options) {
    state = state.copyWith(createOptions: options);
  }

  void clearPageError() {
    state = state.copyWith(clearPageError: true);
  }

  Future<void> initWizard({
    String? resumeProductId,
    String? resumeLocalDraftId,
  }) async {
    state = state.copyWith(isLoadingOptions: true, clearOptionsError: true);

    try {
      final options = await _repository.getCreateOptions();
      state = state.copyWith(createOptions: options, isLoadingOptions: false);

      if (resumeLocalDraftId != null && resumeLocalDraftId.isNotEmpty) {
        await loadLocalDraft(resumeLocalDraftId);
      } else if (resumeProductId != null && resumeProductId.isNotEmpty) {
        if (state.productId == resumeProductId && state.currentStep > 1) {
          // Draft already hydrated and active in session, preserve step state
        } else {
          await loadExistingDraft(resumeProductId);
        }
      } else if (state.productId == null || state.productId!.isEmpty) {
        // Fresh Add Product always starts at Step 1 (Basic Details)
        state = state.copyWith(currentStep: 1);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingOptions: false,
        optionsError: 'Failed to load product options: ${e.toString()}',
      );
    }
  }

  /// Hydrates wizard from device-local draft storage (never GET /setup).
  Future<void> loadLocalDraft(String localDraftId) async {
    final local = _draftLocal;
    if (local == null) {
      state = state.copyWith(
        pageError: 'Local draft storage is unavailable.',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, clearPageError: true);
    try {
      final draft = await local.getDraft(localDraftId);
      if (draft == null) {
        state = state.copyWith(
          isSubmitting: false,
          pageError: 'Local draft was not found on this device.',
        );
        return;
      }

      final options = state.createOptions;
      state = draft.wizardState.copyWith(
        localDraftId: draft.localDraftId,
        status: 'DRAFT',
        createOptions: options,
        isDirty: false,
        isSubmitting: false,
        isSavingDraft: false,
        isLoadingOptions: false,
        clearPageError: true,
        fieldErrors: const {},
      );

      // Resolve to an applicable step (never VARIANT on 3 / SIMPLE on 4).
      final step = resolveApplicableResumeStep(state.currentStep);
      if (step != state.currentStep) {
        state = state.copyWith(currentStep: step);
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        pageError: 'Failed to load local draft: ${_extractErrorMessage(e)}',
      );
    }
  }

  /// Clamps [requestedStep] to an applicable step for the current product type.
  @visibleForTesting
  int resolveApplicableResumeStep(int requestedStep) {
    if (isStepApplicable(requestedStep)) return requestedStep;
    for (var s = requestedStep - 1; s >= 1; s--) {
      if (isStepApplicable(s)) return s;
    }
    for (var s = requestedStep + 1; s <= 7; s++) {
      if (isStepApplicable(s)) return s;
    }
    return 1;
  }

  Future<void> loadExistingDraft(String productId) async {
    state = state.copyWith(isSubmitting: true, clearPageError: true);

    try {
      final draft = await _repository.getSetup(productId);
      _hydrateFromDraftResponse(draft, forceStep: draft.currentSetupStep);
      state = state.copyWith(isSubmitting: false, isDirty: false);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        pageError: 'Failed to load draft: ${_extractErrorMessage(e)}',
      );
    }
  }

  void setProductStructure(String structure) {
    if (structure != 'SIMPLE' &&
        structure != 'VARIANT' &&
        structure != 'BUNDLE') {
      return;
    }
    if (structure == 'BUNDLE') {
      // Exact Second Brain Release 1 rule: Bundle parent tracking is component-derived
      state = state.copyWith(
        productStructure: 'BUNDLE',
        productStructureConfirmed: true,
        trackInventory: false,
        batchTracking: false,
        expiryTracking: false,
        serialTracking: false,
        isDirty: true,
      );
    } else {
      state = state.copyWith(
        productStructure: structure,
        productStructureConfirmed: true,
        isDirty: true,
      );
    }
  }

  void updateProductName(String val) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('productName');
    state = state.copyWith(
      productName: val,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateInternalCode(String val) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('productCode');
    state = state.copyWith(
      internalCode: val,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateCategory(String? categoryId) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('categoryId');
    state = state.copyWith(
      categoryId: categoryId,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateBrand(String? brandId) {
    state = state.copyWith(
      brandId: brandId,
      clearBrandId: brandId == null,
      isDirty: true,
    );
  }

  void updateShortDescription(String val) {
    state = state.copyWith(
      shortDescription: val,
      isDirty: true,
    );
  }

  void updateLongDescription(String val) {
    state = state.copyWith(
      longDescription: val,
      isDirty: true,
    );
  }

  void setDesiredPublishActive(bool val) {
    state = state.copyWith(
      desiredPublishActive: val,
      isDirty: true,
    );
  }

  void setPosSellable(bool val) {
    state = state.copyWith(
      posSellable: val,
      isDirty: true,
    );
  }

  void setTrackInventory(bool val) {
    if (state.productStructure == 'BUNDLE') return; // Locked for Bundle
    if (!val) {
      state = state.copyWith(
        trackInventory: false,
        batchTracking: false,
        expiryTracking: false,
        serialTracking: false,
        isDirty: true,
      );
    } else {
      state = state.copyWith(
        trackInventory: true,
        isDirty: true,
      );
    }
  }

  void setBatchTracking(bool val) {
    if (state.productStructure == 'BUNDLE') return;
    if (!state.trackInventory) return;
    if (state.serialTracking && val) {
      return; // Serial and Batch mutually exclusive
    }

    if (!val) {
      state = state.copyWith(
        batchTracking: false,
        expiryTracking: false,
        isDirty: true,
      );
    } else {
      state = state.copyWith(
        batchTracking: true,
        isDirty: true,
      );
    }
  }

  void setExpiryTracking(bool val) {
    if (state.productStructure == 'BUNDLE') return;
    if (!state.trackInventory) return;
    if (!state.batchTracking && val) return; // Expiry requires Batch
    if (state.serialTracking && val) {
      return; // Serial and Expiry mutually exclusive
    }

    state = state.copyWith(
      expiryTracking: val,
      isDirty: true,
    );
  }

  void setSerialTracking(bool val) {
    if (state.productStructure == 'BUNDLE') return;
    if (!state.trackInventory) return;

    if (val) {
      state = state.copyWith(
        serialTracking: true,
        batchTracking: false,
        expiryTracking: false,
        isDirty: true,
      );
    } else {
      state = state.copyWith(
        serialTracking: false,
        isDirty: true,
      );
    }
  }

  void setAllowOnlineSale(bool val) {
    state = state.copyWith(
      allowOnlineSale: val,
      isDirty: true,
    );
  }

  void openImageManager() {
    state = state.copyWith(isImageManagerOpen: true);
  }

  void closeImageManager() {
    state = state.copyWith(isImageManagerOpen: false);
  }

  // --- IMAGE MANAGEMENT ---

  Future<bool> stageOrUploadImage(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    // Enforce 10 image limit
    if (state.totalImageCount >= 10) {
      state = state.copyWith(pageError: 'Maximum 10 product images allowed');
      return false;
    }

    // Enforce 5MB limit (5,242,880 bytes)
    if (bytes.length > 5242880) {
      state = state.copyWith(
          pageError: 'Image file size exceeds maximum limit of 5MB.');
      return false;
    }

    // Enforce valid image format
    final lowerMime = mimeType.toLowerCase();
    final lowerName = fileName.toLowerCase();
    final isValidFormat = lowerMime.contains('image') ||
        lowerMime.contains('png') ||
        lowerMime.contains('jpeg') ||
        lowerMime.contains('jpg') ||
        lowerMime.contains('webp') ||
        lowerMime.contains('gif') ||
        lowerMime.contains('bmp') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.bmp') ||
        lowerName.endsWith('.jfif') ||
        lowerName.endsWith('.svg') ||
        lowerName.endsWith('.avif') ||
        lowerName.endsWith('.heic') ||
        lowerName.endsWith('.heif') ||
        lowerName.endsWith('.ico');

    if (!isValidFormat) {
      state = state.copyWith(
          pageError:
              'Unsupported image format. Please select a valid image file.');
      return false;
    }

    state = state.copyWith(clearPageError: true);

    try {
      if (state.isEditMode) {
        // Direct upload to existing product
        await _repository.uploadProductImage(
          state.productId!,
          bytes,
          fileName,
          mimeType,
        );
        // Refresh setup details
        await loadExistingDraft(state.productId!);
      } else {
        // Stage image for unsaved product
        final stagedDto =
            await _repository.stageImage(bytes, fileName, mimeType);
        final isFirst = state.stagedMediaAssets.isEmpty;
        final uint8Bytes = Uint8List.fromList(bytes);
        final newStaged = StagedProductImage(
          mediaAssetId: stagedDto.mediaAssetId,
          publicUrl: stagedDto.publicUrl,
          fileName: stagedDto.fileName,
          mimeType: stagedDto.mimeType,
          fileSizeBytes: stagedDto.fileSizeBytes,
          createdAt: stagedDto.createdAt,
          status: stagedDto.status,
          isPrimary: isFirst,
          sortOrder: state.stagedMediaAssets.length + 1,
          bytes: uint8Bytes,
        );

        final updatedList =
            List<StagedProductImage>.from(state.stagedMediaAssets)
              ..add(newStaged);

        // Map to display items
        final wizardImages = updatedList.map((e) {
          return ProductWizardImageItem(
            id: e.mediaAssetId,
            mediaAssetId: e.mediaAssetId,
            imageUrl: e.publicUrl ?? '',
            fileName: e.fileName,
            isPrimary: e.isPrimary,
            sortOrder: e.sortOrder,
            isStaged: true,
            bytes: e.bytes,
          );
        }).toList();

        final primaryId = updatedList
            .firstWhere((e) => e.isPrimary, orElse: () => updatedList.first)
            .mediaAssetId;

        state = state.copyWith(
          stagedMediaAssets: updatedList,
          productImages: wizardImages,
          primaryImageId: primaryId,
          isDirty: true,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        pageError: 'Image upload failed: ${_extractErrorMessage(e)}',
      );
      return false;
    }
  }

  Future<void> setPrimaryImage(String targetId) async {
    if (state.isEditMode) {
      // API call to reorder/set primary
      final items = state.productImages.map((img) {
        return {
          'productImageId': img.id,
          'sortOrder': img.sortOrder,
        };
      }).toList();

      state = state.copyWith(isSubmitting: true, clearPageError: true);
      try {
        final draft = await _repository.reorderProductImages(
          state.productId!,
          state.rowVersion,
          targetId,
          items,
        );
        _hydrateFromDraftResponse(draft);
        state = state.copyWith(isSubmitting: false);
      } catch (e) {
        state = state.copyWith(
          isSubmitting: false,
          pageError:
              'Failed to update primary image: ${_extractErrorMessage(e)}',
        );
      }
    } else {
      // Local staged re-assignment
      final updatedStaged = state.stagedMediaAssets.map((img) {
        return img.copyWith(isPrimary: img.mediaAssetId == targetId);
      }).toList();

      final updatedImages = state.productImages.map((img) {
        return img.copyWith(isPrimary: img.id == targetId);
      }).toList();

      state = state.copyWith(
        stagedMediaAssets: updatedStaged,
        productImages: updatedImages,
        primaryImageId: targetId,
        isDirty: true,
      );
    }
  }

  Future<void> deleteImage(String targetId) async {
    if (state.isEditMode) {
      state = state.copyWith(isSubmitting: true, clearPageError: true);
      try {
        final draft =
            await _repository.deleteProductImage(state.productId!, targetId);
        _hydrateFromDraftResponse(draft);
        state = state.copyWith(isSubmitting: false);
      } catch (e) {
        state = state.copyWith(
          isSubmitting: false,
          pageError: 'Failed to delete image: ${_extractErrorMessage(e)}',
        );
      }
    } else {
      final updatedStaged = state.stagedMediaAssets
          .where((e) => e.mediaAssetId != targetId)
          .toList();

      // If deleted item was primary, promote first remaining item
      if (updatedStaged.isNotEmpty && !updatedStaged.any((e) => e.isPrimary)) {
        updatedStaged[0] = updatedStaged[0].copyWith(isPrimary: true);
      }

      final updatedImages = updatedStaged.map((e) {
        return ProductWizardImageItem(
          id: e.mediaAssetId,
          mediaAssetId: e.mediaAssetId,
          imageUrl: e.publicUrl ?? '',
          fileName: e.fileName,
          isPrimary: e.isPrimary,
          sortOrder: e.sortOrder,
          isStaged: true,
        );
      }).toList();

      final newPrimaryId = updatedStaged.isEmpty
          ? null
          : updatedStaged
              .firstWhere((e) => e.isPrimary, orElse: () => updatedStaged.first)
              .mediaAssetId;

      state = state.copyWith(
        stagedMediaAssets: updatedStaged,
        productImages: updatedImages,
        primaryImageId: newPrimaryId,
        clearPrimaryImageId: newPrimaryId == null,
        isDirty: true,
      );
    }
  }

  Future<void> reorderImages(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final items = List<ProductWizardImageItem>.from(state.productImages);
    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    // Update sort orders
    final reordered = items.asMap().entries.map((entry) {
      return entry.value.copyWith(sortOrder: entry.key + 1);
    }).toList();

    if (state.isEditMode) {
      final payloadItems = reordered.map((img) {
        return {
          'productImageId': img.id,
          'sortOrder': img.sortOrder,
        };
      }).toList();

      state = state.copyWith(productImages: reordered, isSubmitting: true);
      try {
        final draft = await _repository.reorderProductImages(
          state.productId!,
          state.rowVersion,
          state.primaryImageId,
          payloadItems,
        );
        _hydrateFromDraftResponse(draft);
        state = state.copyWith(isSubmitting: false);
      } catch (e) {
        // Rollback optimistic state
        await loadExistingDraft(state.productId!);
        state = state.copyWith(
          isSubmitting: false,
          pageError: 'Failed to reorder images: ${_extractErrorMessage(e)}',
        );
      }
    } else {
      state = state.copyWith(productImages: reordered, isDirty: true);
    }
  }

  // --- WIZARD LIFECYCLE: LOCAL STATE + APPLICABLE-STEP NAVIGATION ---

  /// Chunk 2: Product wizard must not persist products/drafts during Steps 1–6.
  void _logBlockedProductMutation(String source) {
    debugPrint(
      '[ProductWizard] BLOCKED product persistence call from $source '
      '(frontend-local wizard state only)',
    );
  }

  /// SIMPLE: 1→2→3→5→6→7 ; VARIANT/BUNDLE: 1→2→4→5→6→7
  @visibleForTesting
  int getNextApplicableStep([int? fromStep]) {
    final step = fromStep ?? state.currentStep;
    final structure = state.productStructure.toUpperCase();
    switch (step) {
      case 1:
        return 2;
      case 2:
        if (structure == 'VARIANT' || structure == 'BUNDLE') {
          return 4;
        }
        return 3;
      case 3:
        return 5;
      case 4:
        return 5;
      case 5:
        return 6;
      case 6:
        return 7;
      default:
        return step.clamp(1, 7);
    }
  }

  @visibleForTesting
  int getPreviousApplicableStep([int? fromStep]) {
    final step = fromStep ?? state.currentStep;
    final structure = state.productStructure.toUpperCase();
    switch (step) {
      case 7:
        return 6;
      case 6:
        return 5;
      case 5:
        if (structure == 'VARIANT' || structure == 'BUNDLE') {
          return 4;
        }
        return 3;
      case 4:
        return 2;
      case 3:
        return 2;
      case 2:
        return 1;
      default:
        return step.clamp(1, 7);
    }
  }

  @visibleForTesting
  bool isStepApplicable(int step) {
    if (step < 1 || step > 7) return false;
    final structure = state.productStructure.toUpperCase();
    if (step == 3 && (structure == 'VARIANT' || structure == 'BUNDLE')) {
      return false;
    }
    if (step == 4 && structure == 'SIMPLE') {
      return false;
    }
    return true;
  }

  void goToPreviousApplicableStep() {
    final prev = getPreviousApplicableStep();
    if (prev != state.currentStep && prev >= 1) {
      state = state.copyWith(currentStep: prev);
    }
  }

  Future<void> generateVariants() async {
    // Local-only Cartesian generation — no product draft persistence.
    _logBlockedProductMutation('generateVariants');
    state = state.copyWith(isSavingDraft: true, clearPageError: true);

    final validAttrs =
        state.step4State.attributeRows.where((a) => a.isValid).toList();
    if (validAttrs.isEmpty) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError:
            'Add at least one attribute with values before generating variants.',
      );
      return;
    }

    final reconciled = VariantCombinationGenerator.reconcileVariants(
      activeAttributes: state.step4State.attributeRows,
      existingVariants: state.step4State.generatedVariants,
      deletedVariants: state.step4State.deletedVariants,
      productName: state.productName,
    );

    state = state.copyWith(
      step4State: state.step4State.copyWith(generatedVariants: reconciled),
      isSavingDraft: false,
      isDirty: true,
      clearPageError: true,
    );
    reconcileStep5AssignmentsWithVariants();
  }

  /// Keeps Step 5 assignments aligned to included Step 4 variants by
  /// [clientCombinationKey]. Preserves SKU/barcode for retained keys.
  void reconcileStep5AssignmentsWithVariants() {
    if (state.productStructure.toUpperCase() != 'VARIANT') return;

    final included = state.step4State.generatedVariants
        .where((v) => v.isIncluded)
        .toList();
    final existingByKey = <String, BarcodeSkuAssignmentDto>{
      for (final a in state.step5State.assignments) a.clientCombinationKey: a,
    };

    final next = <BarcodeSkuAssignmentDto>[];
    for (final variant in included) {
      final previous = existingByKey[variant.clientCombinationKey];
      final sku = previous?.sku;
      final barcode = previous?.barcode;
      next.add(
        BarcodeSkuAssignmentDto(
          clientCombinationKey: variant.clientCombinationKey,
          // Fresh create: null. Resume/edit may already carry a real id.
          productVariantId: previous?.productVariantId,
          sku: sku,
          barcode: barcode,
          isAssigned: (sku?.trim().isNotEmpty ?? false) ||
              (barcode?.trim().isNotEmpty ?? false),
        ),
      );
    }

    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: next),
      isDirty: true,
    );
  }

  void ensureVariantStep5Targets() {
    reconcileStep5AssignmentsWithVariants();
  }

  /// Persists the current wizard snapshot to device-local storage only.
  /// Does not create/update a backend product. Allows partial/incomplete data.
  Future<bool> saveDraft() async {
    _logBlockedProductMutation('saveDraft');
    state = state.copyWith(isSavingDraft: true, clearPageError: true);

    final local = _draftLocal;
    if (local == null) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError: 'Local draft storage is unavailable.',
      );
      return false;
    }

    try {
      // Commit SIMPLE projection so Step 5 fields are in assignments too.
      final structure = state.productStructure.toUpperCase();
      if (structure == 'SIMPLE' || structure == 'BUNDLE') {
        commitSimpleBarcodeSkuToState();
      } else if (structure == 'VARIANT') {
        reconcileStep5AssignmentsWithVariants();
      }

      final draftId = state.localDraftId ?? _newLocalDraftId();
      DateTime? createdAt;
      if (state.localDraftId != null) {
        final existing = await local.getDraft(draftId);
        createdAt = existing?.createdAt;
      }

      final now = DateTime.now().toUtc();
      final snapshot = state.copyWith(
        localDraftId: draftId,
        status: 'DRAFT',
        isDirty: false,
        isSavingDraft: false,
        clearPageError: true,
        fieldErrors: const {},
      );

      final draft = ProductWizardDraft.fromWizardState(
        state: snapshot,
        localDraftId: draftId,
        createdAt: createdAt,
        updatedAt: now,
      );

      await local.saveDraft(draft);

      state = snapshot.copyWith(
        localDraftId: draftId,
        createOptions: state.createOptions,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError: 'Failed to save local draft: ${_extractErrorMessage(e)}',
      );
      return false;
    }
  }

  String _newLocalDraftId() {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'local-$now-$rand';
  }

  /// Sole backend Product persistence action (Step 7 Create Product).
  /// Does not call draft save/update APIs.
  Future<bool> createProductFromWizard() async {
    if (state.isSubmitting) {
      return false;
    }

    final structure = state.productStructure.toUpperCase();
    if (structure == 'SIMPLE' || structure == 'BUNDLE') {
      commitSimpleBarcodeSkuToState();
    } else if (structure == 'VARIANT') {
      reconcileStep5AssignmentsWithVariants();
    }

    final step5Errors = validateStep5Continue();
    final step6Errors = <String, String>{};
    if (state.standardSellingPrice == null ||
        state.standardSellingPrice! <= 0) {
      step6Errors['standardSellingPrice'] =
          'Standard selling price is required.';
    }

    final errors = {...step5Errors, ...step6Errors};
    if (errors.isNotEmpty) {
      state = state.copyWith(
        fieldErrors: errors,
        pageError: errors.values.first,
        isSubmitting: false,
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearPageError: true);
    final idempotencyKey = state.localDraftId ??
        'create-${DateTime.now().toUtc().microsecondsSinceEpoch}';

    try {
      final payload = WizardProductCreateMapper.toWizardCreateJson(
        state,
        idempotencyKey: idempotencyKey,
      );
      final result = await _repository.createProductFromWizard(payload);

      final draftId = state.localDraftId;
      if (draftId != null &&
          draftId.isNotEmpty &&
          _draftLocal != null) {
        await _draftLocal!.deleteDraft(draftId);
      }

      state = state.copyWith(
        productId: result.id,
        status: result.status,
        isSubmitting: false,
        isDirty: false,
        clearLocalDraftId: true,
        clearPageError: true,
        fieldErrors: const {},
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        pageError: 'Failed to create product: ${_extractErrorMessage(e)}',
      );
      return false;
    }
  }

  /// Validate current step, commit to wizard state, navigate locally.
  /// Steps 1–6 never call product create/update/draft APIs.
  /// Step 7 performs the sole backend Product Create (wizard-create).
  Future<bool> saveAndContinue() async {
    if (state.currentStep == 7) {
      return createProductFromWizard();
    }

    final errors = <String, String>{};
    final trimmedName = state.productName.trim();

    if (state.currentStep == 1) {
      if (trimmedName.isEmpty ||
          trimmedName.toLowerCase() == 'untitled product') {
        errors['productName'] = 'Product name is required.';
      }

      if (state.categoryId == null || state.categoryId!.isEmpty) {
        errors['categoryId'] = 'Category is required.';
      }
    }

    if (state.currentStep == 2) {
      if (!state.productStructureConfirmed) {
        state = state.copyWith(
          pageError:
              'Please explicitly select a Product Type before continuing.',
        );
        return false;
      }
    }

    if (state.currentStep == 3) {
      final step3Errors = validateStep3Continue();
      if (step3Errors.isNotEmpty) {
        errors.addAll(step3Errors);
      }
    }

    if (state.currentStep == 4) {
      final step4Errors = validateStep4Continue();
      if (step4Errors.isNotEmpty) {
        errors.addAll(step4Errors);
      } else {
        reconcileStep5AssignmentsWithVariants();
      }
    }

    if (state.currentStep == 5) {
      final structure = state.productStructure.toUpperCase();
      if (structure == 'SIMPLE' || structure == 'BUNDLE') {
        commitSimpleBarcodeSkuToState();
      } else if (structure == 'VARIANT') {
        reconcileStep5AssignmentsWithVariants();
      }
      final step5Errors = validateStep5Continue();
      if (step5Errors.isNotEmpty) {
        errors.addAll(step5Errors);
      }
    }

    if (state.currentStep == 6) {
      if (state.costPrice == null || state.costPrice! <= 0) {
        errors['costPrice'] =
            'Cost Price is required and must be greater than zero.';
      }
      if (state.standardSellingPrice == null ||
          state.standardSellingPrice! <= 0) {
        errors['standardSellingPrice'] =
            'Standard Selling Price is required and must be greater than zero.';
      }
      if (state.discountPrice != null && state.discountPrice! < 0) {
        errors['discountPrice'] = 'Discount Price cannot be negative.';
      }
      if (state.discountPrice != null &&
          state.standardSellingPrice != null &&
          state.discountPrice! > state.standardSellingPrice!) {
        errors['discountPrice'] =
            'Discount Price cannot exceed Standard Selling Price.';
      }
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(
        fieldErrors: errors,
        pageError: 'Please fix validation errors before continuing.',
      );
      return false;
    }

    _logBlockedProductMutation('saveAndContinue(step${state.currentStep})');

    final nextStep = getNextApplicableStep();
    final completed = state.currentStep;

    state = state.copyWith(
      currentStep: nextStep,
      lastCompletedSetupStep: completed,
      targetSetupStep: nextStep,
      isSubmitting: false,
      clearPageError: true,
      fieldErrors: const {},
      // Keep dirty so Cancel still warns; values remain in state.
      isDirty: true,
    );
    return true;
  }

  /// Manual Skip is disabled. Non-applicable steps are skipped by routing.
  Future<bool> skip() async {
    _logBlockedProductMutation('skip');
    state = state.copyWith(
      pageError:
          'Skip is not available. Non-applicable steps are skipped automatically.',
    );
    return false;
  }

  void goToStep(int step) {
    if (!isStepApplicable(step)) return;
    // Stepper may only jump back to an earlier applicable step.
    if (step >= 1 && step < state.currentStep) {
      state = state.copyWith(currentStep: step);
    }
  }

  void selectUnitModel(String model) {
    if (model != 'SINGLE_UNIT' && model != 'MULTIPLE_UNITS') return;
    state = state.copyWith(
      unitModel: model,
      isDirty: true,
    );
  }

  void setProductUnit(String? unitId) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('productUnitId')
      ..remove('baseUnitId');

    bool? defaultDecimal;
    if (unitId != null && state.createOptions != null) {
      final matched = state.createOptions!.units.firstWhere(
        (u) => u.id == unitId,
        orElse: () => ProductUnitOption(id: '', code: '', name: ''),
      );
      if (matched.recommendedAllowDecimalQuantity != null) {
        defaultDecimal = matched.recommendedAllowDecimalQuantity;
      }
    }

    state = state.copyWith(
      productUnitId: unitId,
      baseUnitId: unitId,
      clearProductUnitId: unitId == null,
      clearBaseUnitId: unitId == null,
      allowDecimalQuantity: defaultDecimal ?? state.allowDecimalQuantity,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void setBaseUnit(String? unitId) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('baseUnitId');

    bool? defaultDecimal;
    if (unitId != null && state.createOptions != null) {
      final matched = state.createOptions!.units.firstWhere(
        (u) => u.id == unitId,
        orElse: () => ProductUnitOption(id: '', code: '', name: ''),
      );
      if (matched.recommendedAllowDecimalQuantity != null) {
        defaultDecimal = matched.recommendedAllowDecimalQuantity;
      }
    }

    final newSellingId = state.sellingUnitId ?? unitId;

    state = state.copyWith(
      baseUnitId: unitId,
      sellingUnitId: newSellingId,
      clearBaseUnitId: unitId == null,
      allowDecimalQuantity: defaultDecimal ?? state.allowDecimalQuantity,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void setSellingUnit(String? unitId) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('sellingUnitId');
    state = state.copyWith(
      sellingUnitId: unitId,
      clearSellingUnitId: unitId == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void setPurchaseUnit(String? unitId) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('purchaseUnitId');
    state = state.copyWith(
      purchaseUnitId: unitId,
      clearPurchaseUnitId: unitId == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void setItemsPerPurchaseUnit(num? factor) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('itemsPerPurchaseUnit');
    state = state.copyWith(
      itemsPerPurchaseUnit: factor,
      clearItemsPerPurchaseUnit: factor == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void setOuterPackUnit(String? unitId) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('outerPackUnitId');
    state = state.copyWith(
      outerPackUnitId: unitId,
      clearOuterPackUnitId: unitId == null,
      purchaseUnitsPerOuterPack:
          unitId == null ? null : state.purchaseUnitsPerOuterPack,
      clearPurchaseUnitsPerOuterPack: unitId == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void setPurchaseUnitsPerOuterPack(num? factor) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('purchaseUnitsPerOuterPack');
    state = state.copyWith(
      purchaseUnitsPerOuterPack: factor,
      clearPurchaseUnitsPerOuterPack: factor == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void setAllowDecimalQuantity(bool val) {
    state = state.copyWith(
      allowDecimalQuantity: val,
      isDirty: true,
    );
  }

  Map<String, String> validateStep3Continue() {
    final errors = <String, String>{};

    if (state.unitModel == 'SINGLE_UNIT') {
      final singleId = state.productUnitId ?? state.baseUnitId;
      if (singleId == null || singleId.isEmpty) {
        errors['productUnitId'] =
            'Product Unit is required for Single Unit model.';
      }
    } else if (state.unitModel == 'MULTIPLE_UNITS') {
      if (state.baseUnitId == null || state.baseUnitId!.isEmpty) {
        errors['baseUnitId'] =
            'Base Unit is required for Multiple Units model.';
      }
      if (state.sellingUnitId == null || state.sellingUnitId!.isEmpty) {
        errors['sellingUnitId'] =
            'Selling Unit is required for Multiple Units model.';
      }
      if (state.purchaseUnitId == null || state.purchaseUnitId!.isEmpty) {
        errors['purchaseUnitId'] =
            'Purchase Unit is required for Multiple Units model.';
      }
      if (state.baseUnitId != null &&
          state.purchaseUnitId != null &&
          state.baseUnitId == state.purchaseUnitId) {
        errors['purchaseUnitId'] = 'Purchase Unit must differ from Base Unit.';
      }
      if (state.itemsPerPurchaseUnit == null ||
          state.itemsPerPurchaseUnit! <= 0) {
        errors['itemsPerPurchaseUnit'] =
            'Items per Purchase Unit is required and must be greater than zero.';
      }
      if (state.outerPackUnitId != null && state.outerPackUnitId!.isNotEmpty) {
        if (state.baseUnitId != null &&
            state.outerPackUnitId == state.baseUnitId) {
          errors['outerPackUnitId'] =
              'Outer Pack Unit must differ from Base Unit.';
        }
        if (state.purchaseUnitId != null &&
            state.outerPackUnitId == state.purchaseUnitId) {
          errors['outerPackUnitId'] =
              'Outer Pack Unit must differ from Purchase Unit.';
        }
        if (state.purchaseUnitsPerOuterPack == null ||
            state.purchaseUnitsPerOuterPack! <= 0) {
          errors['purchaseUnitsPerOuterPack'] =
              'Purchase Units per Outer Pack is required when Outer Pack Unit is selected.';
        }
      }

      if (state.sellingUnitId != null && state.sellingUnitId!.isNotEmpty) {
        final isBase =
            state.baseUnitId != null && state.sellingUnitId == state.baseUnitId;
        final isPurchase = state.purchaseUnitId != null &&
            state.sellingUnitId == state.purchaseUnitId;
        final isOuter = state.outerPackUnitId != null &&
            state.sellingUnitId == state.outerPackUnitId;

        if (!isBase && !isPurchase && !isOuter) {
          errors['sellingUnitId'] =
              'Selling Unit must match Base Unit, Purchase Unit, or Outer Pack Unit.';
        }
      }

      if (!state.allowDecimalQuantity) {
        if (state.itemsPerPurchaseUnit != null &&
            state.itemsPerPurchaseUnit! % 1 != 0) {
          errors['allowDecimalQuantity'] =
              'Items per Purchase Unit has a fractional part, which requires Decimal Quantity to be enabled.';
        }
        if (state.itemsPerPurchaseUnit != null &&
            state.purchaseUnitsPerOuterPack != null &&
            (state.itemsPerPurchaseUnit! * state.purchaseUnitsPerOuterPack!) %
                    1 !=
                0) {
          errors['allowDecimalQuantity'] =
              'Outer Pack conversion factor has a fractional part, which requires Decimal Quantity to be enabled.';
        }
      }
    }

    return errors;
  }

  Map<String, String> validateStep4Continue() {
    final errors = <String, String>{};
    if (state.productStructure.toUpperCase() != 'VARIANT') {
      return errors;
    }

    final validAttrs =
        state.step4State.attributeRows.where((a) => a.isValid).toList();
    if (validAttrs.isEmpty) {
      errors['variantAttributes'] =
          'Add at least one attribute with values before continuing.';
    }

    final included = state.step4State.generatedVariants
        .where((v) => v.isIncluded)
        .toList();
    if (included.isEmpty) {
      errors['generatedVariants'] =
          'Generate and include at least one variant before continuing.';
    }

    return errors;
  }

  Map<String, String> validateStep5Continue() {
    final errors = <String, String>{};
    final structure = state.productStructure.toUpperCase();

    if (structure == 'SIMPLE' || structure == 'BUNDLE') {
      if (state.step5State.baseSku.trim().isEmpty) {
        errors['sku'] = 'Base SKU is required.';
      } else if (state.step5State.baseSku.trim().length > 80) {
        errors['sku'] = 'Base SKU must be 80 characters or fewer.';
      }
      return errors;
    }

    if (structure == 'VARIANT') {
      final includedKeys = state.step4State.generatedVariants
          .where((v) => v.isIncluded)
          .map((v) => v.clientCombinationKey)
          .toSet();

      final activeAssignments = state.step5State.assignments
          .where((a) => includedKeys.contains(a.clientCombinationKey))
          .toList();

      if (includedKeys.isEmpty) {
        errors['sku'] = 'No active variants available for SKU assignment.';
        return errors;
      }

      final missingSku = activeAssignments
          .where((a) => a.sku == null || a.sku!.trim().isEmpty)
          .toList();
      // Also catch included variants with no assignment row yet.
      final assignedKeys =
          activeAssignments.map((a) => a.clientCombinationKey).toSet();
      final missingRows =
          includedKeys.where((k) => !assignedKeys.contains(k)).length;

      if (missingSku.isNotEmpty || missingRows > 0) {
        errors['sku'] =
            'Assign a Base SKU to every active variant before continuing.';
      }

      final skuCounts = <String, int>{};
      for (final a in activeAssignments) {
        final sku = a.sku?.trim().toUpperCase();
        if (sku == null || sku.isEmpty) continue;
        skuCounts[sku] = (skuCounts[sku] ?? 0) + 1;
      }
      if (skuCounts.values.any((c) => c > 1)) {
        errors['skuDuplicate'] =
            'Duplicate SKU values are not allowed within this product.';
      }

      final barcodeCounts = <String, int>{};
      for (final a in activeAssignments) {
        final barcode = a.barcode?.trim();
        if (barcode == null || barcode.isEmpty) continue;
        barcodeCounts[barcode] = (barcodeCounts[barcode] ?? 0) + 1;
      }
      if (barcodeCounts.values.any((c) => c > 1)) {
        errors['barcodeDuplicate'] =
            'Duplicate barcode values are not allowed within this product.';
      }
    }

    return errors;
  }

  void _hydrateFromDraftResponse(ProductDraftResponseDto draft,
      {int? forceStep, bool keepDirtyStatus = false}) {
    final images = draft.images.map((img) {
      return ProductWizardImageItem(
        id: img.productImageId,
        mediaAssetId: img.mediaAssetId,
        imageUrl: img.imageUrl,
        fileName: 'Image ${img.sortOrder}',
        isPrimary: img.isPrimaryImage,
        sortOrder: img.sortOrder,
        isStaged: false,
      );
    }).toList();

    final primaryImg = draft.images.firstWhere((e) => e.isPrimaryImage,
        orElse: () => draft.images.isNotEmpty
            ? draft.images.first
            : const ProductImageResponseDto(
                productImageId: '',
                imageUrl: '',
                imagePurpose: '',
                sortOrder: 0,
                isPrimaryImage: false));

    final resolvedStep = forceStep ??
        (draft.currentSetupStep > state.currentStep
            ? draft.currentSetupStep
            : state.currentStep);

    final conversions = draft.unitConversions.map((c) {
      return ProductUnitConversionItem(
        uomId: c.uomId,
        uomCode: c.uomCode,
        uomName: c.uomName,
        unitLevel: c.unitLevel,
        conversionToBaseFactor: c.conversionToBaseFactor,
        isBaseUnit: c.isBaseUnit,
        isSellingUnit: c.isSellingUnit,
        isPurchaseUnit: c.isPurchaseUnit,
        isOuterPackUnit: c.isOuterPackUnit,
      );
    }).toList();

    final step4State =
        _mapVariantConfigState(draft.variantConfiguration, state.createOptions);

    final assignments =
        draft.barcodeSkuConfiguration?.assignments ??
            const <BarcodeSkuAssignmentDto>[];
    BarcodeSkuAssignmentDto? simpleAssignment;
    for (final a in assignments) {
      if (a.clientCombinationKey == 'SIMPLE_DEFAULT') {
        simpleAssignment = a;
        break;
      }
    }
    simpleAssignment ??= assignments.length == 1 ? assignments.first : null;

    final step5State = state.step5State.copyWith(
      baseSku: simpleAssignment?.sku ?? state.step5State.baseSku,
      parentProductBarcode:
          simpleAssignment?.barcode ?? state.step5State.parentProductBarcode,
      identifierTargets:
          draft.barcodeSkuConfiguration?.identifierTargets ?? const [],
      assignments: assignments,
      clearDuplicateBarcodeConflict: true,
    );

    state = state.copyWith(
      productId: draft.productId,
      status: draft.status,
      rowVersion: draft.rowVersion,
      currentStep: resolvedStep,
      targetSetupStep: draft.targetSetupStep,
      lastCompletedSetupStep: draft.lastCompletedSetupStep,
      productName:
          draft.productName == 'Untitled Product' ? '' : draft.productName,
      internalCode: (draft.productCode != null && draft.productCode!.startsWith('DRF-'))
          ? state.internalCode
          : (draft.productCode ?? ''),
      categoryId: draft.categoryId,
      brandId: draft.brandId,
      clearBrandId: draft.brandId == null,
      shortDescription: draft.shortDescription ?? '',
      longDescription: draft.longDescription ?? '',
      posSellable: draft.posSellable,
      trackInventory: draft.trackInventory,
      allowOnlineSale: draft.allowOnlineSale,
      productStructure: draft.productStructure,
      productStructureConfirmed: draft.productId.isNotEmpty,
      batchTracking: draft.batchTracking,
      expiryTracking: draft.expiryTracking,
      serialTracking: draft.serialTracking,
      inventoryMethod: draft.inventoryMethod,
      componentCount: draft.componentCount,
      componentsConfigured: draft.componentsConfigured,
      unitModel: draft.unitModel ?? state.unitModel,
      productUnitId: draft.baseUnitId ?? state.productUnitId,
      baseUnitId: draft.baseUnitId ?? state.baseUnitId,
      baseUnitName: draft.baseUnitName ?? state.baseUnitName,
      sellingUnitId: draft.sellingUnitId ?? state.sellingUnitId,
      sellingUnitName: draft.sellingUnitName ?? state.sellingUnitName,
      purchaseUnitId: draft.purchaseUnitId ?? state.purchaseUnitId,
      purchaseUnitName: draft.purchaseUnitName ?? state.purchaseUnitName,
      outerPackUnitId: draft.outerPackUnitId ?? state.outerPackUnitId,
      outerPackUnitName: draft.outerPackUnitName ?? state.outerPackUnitName,
      itemsPerPurchaseUnit:
          draft.itemsPerPurchaseUnit ?? state.itemsPerPurchaseUnit,
      purchaseUnitsPerOuterPack:
          draft.purchaseUnitsPerOuterPack ?? state.purchaseUnitsPerOuterPack,
      allowDecimalQuantity: draft.allowDecimalQuantity,
      unitConversions: conversions,
      stagedMediaAssets: const [],
      productImages: images.isNotEmpty
          ? images
          : (state.stagedMediaAssets.isNotEmpty
              ? state.stagedMediaAssets.map((e) {
                  return ProductWizardImageItem(
                    id: e.mediaAssetId,
                    mediaAssetId: e.mediaAssetId,
                    imageUrl: e.publicUrl ?? '',
                    fileName: e.fileName,
                    isPrimary: e.isPrimary,
                    sortOrder: e.sortOrder,
                    isStaged: true,
                    bytes: e.bytes,
                  );
                }).toList()
              : images),
      primaryImageId: primaryImg.productImageId.isNotEmpty
          ? primaryImg.productImageId
          : (state.stagedMediaAssets.isNotEmpty
              ? state.stagedMediaAssets
                  .firstWhere((e) => e.isPrimary,
                      orElse: () => state.stagedMediaAssets.first)
                  .mediaAssetId
              : null),
      step4State: step4State,
      step5State: step5State,
      costPrice: draft.pricingTaxConfiguration?.costPrice,
      standardSellingPrice: draft.pricingTaxConfiguration?.standardSellingPrice,
      discountPrice: draft.pricingTaxConfiguration?.discountPrice,
      taxId: draft.pricingTaxConfiguration?.taxId,
      taxRate: draft.pricingTaxConfiguration?.taxRate,
      taxExclusive: draft.pricingTaxConfiguration?.taxExclusive ?? true,
      isDirty: keepDirtyStatus ? state.isDirty : false,
    );
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.statusCode == 409) {
        return 'Draft modified in another session (concurrency conflict). Please reload.';
      }
      final data = e.response?.data;
      if (data is Map) {
        final details = data['details'];
        if (details is List && details.isNotEmpty) {
          final messages = details
              .whereType<Map>()
              .map((d) => d['message']?.toString())
              .where((m) => m != null && m.isNotEmpty)
              .join(' ');
          if (messages.isNotEmpty) {
            return messages;
          }
        }
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return msg;
        }
      }
    }
    return e.toString();
  }

  // --- STEP 4 WIZARD LOGIC ---
  void addAttributeRow() {
    final rows = List<AttributeConfigRow>.from(state.step4State.attributeRows);
    rows.add(AttributeConfigRow());
    state = state.copyWith(
      step4State: state.step4State.copyWith(attributeRows: rows),
      isDirty: true,
    );
  }

  void removeAttributeRow(int index) {
    final rows = List<AttributeConfigRow>.from(state.step4State.attributeRows);
    if (index >= 0 && index < rows.length) {
      rows.removeAt(index);
      state = state.copyWith(
        step4State: state.step4State.copyWith(attributeRows: rows),
        isDirty: true,
      );
    }
  }

  void updateAttributeName(int index, String name) {
    final rows = List<AttributeConfigRow>.from(state.step4State.attributeRows);
    if (index >= 0 && index < rows.length) {
      rows[index] = rows[index].copyWith(
        templateId: name,
        templateName: name,
      );
      state = state.copyWith(
        step4State: state.step4State.copyWith(attributeRows: rows),
        isDirty: true,
      );
    }
  }

  void selectAttribute(int index, String templateId) {
    final template = state.createOptions?.variantOptionTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => ProductVariantOptionTemplate(
          id: '', code: '', name: '', optionType: ''),
    );

    final rows = List<AttributeConfigRow>.from(state.step4State.attributeRows);
    if (index >= 0 && index < rows.length) {
      rows[index] = rows[index].copyWith(
        templateId: templateId,
        templateName: template?.name ?? '',
        selectedValues: [], // Clear values when attribute changes
      );
      state = state.copyWith(
        step4State: state.step4State.copyWith(attributeRows: rows),
        isDirty: true,
      );
    }
  }

  void selectValues(int index, List<String> valueIds) {
    final rows = List<AttributeConfigRow>.from(state.step4State.attributeRows);
    if (index >= 0 && index < rows.length) {
      final templateId = rows[index].templateId;
      if (templateId == null) return;

      final selectedVals = <SelectedOptionValue>[];
      for (final vId in valueIds) {
        // Find value definition if available in createOptions (assuming it has values,
        // currently TenantProductCreateOptionsDto doesn't expose values, so we just use the ID as name for now
        // or wait, let's just create it with valueId)
        selectedVals.add(SelectedOptionValue(
          valueId: vId,
          templateId: templateId,
          valueName:
              vId, // Ideally resolve name, assuming UI provides it or we look it up
        ));
      }

      rows[index] = rows[index].copyWith(selectedValues: selectedVals);
      state = state.copyWith(
        step4State: state.step4State.copyWith(attributeRows: rows),
        isDirty: true,
      );
    }
  }



  void updateVariantDisplayLabel(String key, String label) {
    final variants =
        List<GeneratedVariantRow>.from(state.step4State.generatedVariants);
    final idx = variants.indexWhere((v) => v.clientCombinationKey == key);
    if (idx >= 0) {
      variants[idx] = variants[idx].copyWith(displayLabel: label);
      state = state.copyWith(
        step4State: state.step4State.copyWith(generatedVariants: variants),
        isDirty: true,
      );
    }
  }

  void toggleVariantInclusion(String key, bool included) {
    final variants =
        List<GeneratedVariantRow>.from(state.step4State.generatedVariants);
    final idx = variants.indexWhere((v) => v.clientCombinationKey == key);
    if (idx >= 0) {
      variants[idx] = variants[idx].copyWith(isIncluded: included);
      state = state.copyWith(
        step4State: state.step4State.copyWith(generatedVariants: variants),
        isDirty: true,
      );
      reconcileStep5AssignmentsWithVariants();
    }
  }

  void confirmDeleteVariant(String key) {
    final variants =
        List<GeneratedVariantRow>.from(state.step4State.generatedVariants);
    final deleted =
        List<DeletedVariantTombstone>.from(state.step4State.deletedVariants);

    final index = variants.indexWhere((v) => v.clientCombinationKey == key);
    if (index >= 0) {
      final v = variants[index];
      deleted.add(DeletedVariantTombstone(
        clientCombinationKey: v.clientCombinationKey,
        productVariantId: v.productVariantId,
        optionCombinationHash: v.optionCombinationHash,
        selectedValues: v.selectedValues,
      ));
      variants.removeAt(index);
    }

    state = state.copyWith(
      step4State: state.step4State.copyWith(
        generatedVariants: variants,
        deletedVariants: deleted,
      ),
      isDirty: true,
    );
    reconcileStep5AssignmentsWithVariants();
  }

  Step4VariantConfigurationState _mapVariantConfigState(
      VariantConfigurationResponseDto? dto,
      TenantProductCreateOptions? options) {
    if (dto == null) return const Step4VariantConfigurationState();

    final attributeRows = dto.options.map((opt) {
      final templates = options?.variantOptionTemplates
          .where((t) => t.id == opt.sourceOptionTemplateId);
      final template = (templates != null && templates.isNotEmpty) ? templates.first : null;
      final templateName = opt.optionName ?? template?.name ?? '';
      
      // Fallback templateId to optionName if source template is empty
      final tId = (opt.sourceOptionTemplateId.isNotEmpty) ? opt.sourceOptionTemplateId : (opt.optionName ?? '');

      return AttributeConfigRow(
        templateId: tId.isNotEmpty ? tId : null,
        templateName: templateName,
        selectedValues: opt.values
            .map((v) {
              final vId = (v.sourceOptionTemplateValueId.isNotEmpty) ? v.sourceOptionTemplateValueId : (v.valueName ?? '');
              return SelectedOptionValue(
                  valueId: vId,
                  templateId: tId.isNotEmpty ? tId : null,
                  valueName: v.valueName ?? vId,
                );
            })
            .toList(),
      );
    }).toList();

    final variants = dto.variants.map((v) {
      return GeneratedVariantRow(
        clientCombinationKey: v.clientCombinationKey,
        productVariantId: v.productVariantId,
        combinationLabel: v.combinationLabel,
        displayLabel: v.displayLabel,
        isIncluded: v.includeVariant,
        exactImageMediaAssetId: v.exactImageMediaAssetId,
        optionCombinationHash: v.optionCombinationHash,
        selectedValues: v.selectedValues
            .map((sv) {
              final tId = sv.sourceOptionTemplateId.isNotEmpty ? sv.sourceOptionTemplateId : sv.optionName;
              final vId = sv.sourceOptionTemplateValueId.isNotEmpty ? sv.sourceOptionTemplateValueId : sv.valueName;
              
              return SelectedOptionValue(
                  valueId: vId ?? '',
                  templateId: tId,
                  valueName: sv.valueName ?? vId ?? '',
                );
            })
            .toList(),
      );
    }).toList();

    final deleted = dto.deletedCombinations.map((d) {
      return DeletedVariantTombstone(
        clientCombinationKey: d.clientCombinationKey,
        productVariantId: d.productVariantId,
        optionCombinationHash: d.optionCombinationHash,
        selectedValues: d.selectedValues
            .map((sv) {
              final tId = sv.sourceOptionTemplateId.isNotEmpty ? sv.sourceOptionTemplateId : sv.optionName;
              final vId = sv.sourceOptionTemplateValueId.isNotEmpty ? sv.sourceOptionTemplateValueId : sv.valueName;
              return SelectedOptionValue(
                  valueId: vId ?? '',
                  templateId: tId,
                  valueName: sv.valueName ?? vId ?? '',
                );
            })
            .toList(),
      );
    }).toList();

    return Step4VariantConfigurationState(
      attributeRows: attributeRows,
      generatedVariants: variants,
      deletedVariants: deleted,
    );
  }

  // --- STEP 6 LOGIC ---
  void updateCostPrice(num? price) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('costPrice');
    state = state.copyWith(
      costPrice: price,
      clearCostPrice: price == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateStandardSellingPrice(num? price) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('standardSellingPrice');
    state = state.copyWith(
      standardSellingPrice: price,
      clearStandardSellingPrice: price == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateDiscountPrice(num? price) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('discountPrice');
    state = state.copyWith(
      discountPrice: price,
      clearDiscountPrice: price == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateTaxId(String? taxId, {num? taxRate, String? taxName}) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('taxId');
    state = state.copyWith(
      taxId: taxId,
      clearTaxId: taxId == null,
      taxName: taxName,
      clearTaxName: taxId == null,
      taxRate: taxRate,
      clearTaxRate: taxRate == null && taxId == null,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  // --- STEP 5 LOGIC ---
  void updateSimpleBaseSku(String sku) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('sku');
    state = state.copyWith(
      step5State: state.step5State.copyWith(baseSku: sku),
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateSimpleParentBarcode(String barcode) {
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('barcode');
    state = state.copyWith(
      step5State: state.step5State.copyWith(parentProductBarcode: barcode),
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  /// Explicit Generate action for SIMPLE — writes only to wizard state.
  void generateSimpleIdentifiers({bool overwriteSku = true}) {
    _logBlockedProductMutation('generateSimpleIdentifiers');
    final generated = generateSkuStringForVariant('SIMPLE_DEFAULT');
    if (generated == null || generated.isEmpty) {
      state = state.copyWith(
        pageError:
            'Enter an Internal Code in Basic Details before generating a SKU.',
      );
      return;
    }

    final nextSku = (!overwriteSku && state.step5State.baseSku.trim().isNotEmpty)
        ? state.step5State.baseSku
        : generated;

    state = state.copyWith(
      step5State: state.step5State.copyWith(baseSku: nextSku),
      clearPageError: true,
      isDirty: true,
      fieldErrors: Map<String, String>.from(state.fieldErrors)..remove('sku'),
    );
  }

  /// Commits SIMPLE SKU/barcode into the shared assignment projection (still no variant id).
  void commitSimpleBarcodeSkuToState() {
    final sku = state.step5State.baseSku.trim();
    final barcode = state.step5State.parentProductBarcode.trim();
    final assignment = BarcodeSkuAssignmentDto(
      clientCombinationKey: 'SIMPLE_DEFAULT',
      productVariantId: null,
      sku: sku.isEmpty ? null : sku,
      barcode: barcode.isEmpty ? null : barcode,
      isAssigned: sku.isNotEmpty || barcode.isNotEmpty,
    );
    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: [assignment]),
      isDirty: true,
    );
  }

  void updateBarcodeSkuAssignment(BarcodeSkuAssignmentDto updatedAssignment) {
    final list = List<BarcodeSkuAssignmentDto>.from(state.step5State.assignments);
    final idx = list.indexWhere(
        (e) => e.clientCombinationKey == updatedAssignment.clientCombinationKey);
    
    if (idx >= 0) {
      list[idx] = updatedAssignment;
    } else {
      list.add(updatedAssignment);
    }

    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: list),
      isDirty: true,
    );
  }

  /// Assigns a barcode/SKU entry into wizard state only (no product DB write).
  Future<bool> assignBarcodeSkuAndSave(BarcodeSkuAssignmentDto newAssignment) async {
    _logBlockedProductMutation('assignBarcodeSkuAndSave');
    final fresh = state.productId == null || state.productId!.isEmpty;
    updateBarcodeSkuAssignment(
      newAssignment.copyWith(
        clearProductVariantId: fresh,
        isAssigned: (newAssignment.sku?.trim().isNotEmpty ?? false) ||
            (newAssignment.barcode?.trim().isNotEmpty ?? false),
      ),
    );
    return true;
  }

  void clearDuplicateConflict() {
    state = state.copyWith(
      step5State: state.step5State.copyWith(clearDuplicateBarcodeConflict: true),
    );
  }

  /// Generates an SKU string for the given variant based on product code.
  /// Pattern: {ProductCode}-{VariantLabel} or {ProductCode}-001 for simple.
  /// Returns null if the product code is not yet set.
  String? generateSkuStringForVariant(String clientCombinationKey) {
    final code = state.internalCode.trim();
    if (code.isEmpty || code.startsWith('DRF-')) return null;

    if (state.productStructure == 'SIMPLE' ||
        state.productStructure == 'BUNDLE') {
      return code;
    }

    // VARIANT: use variant label as suffix
    final variant = state.step4State.generatedVariants.firstWhere(
      (v) => v.clientCombinationKey == clientCombinationKey,
      orElse: () => const GeneratedVariantRow(
        clientCombinationKey: '',
        combinationLabel: '',
      ),
    );

    if (variant.clientCombinationKey.isEmpty) return null;

    final label = (variant.displayLabel ?? variant.combinationLabel)
        .replaceAll(' / ', '-')
        .replaceAll(' ', '-')
        .toUpperCase();

    return '$code-$label';
  }
}
