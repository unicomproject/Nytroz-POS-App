import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_draft_response_dto.dart';
import '../../data/models/save_product_draft_request_dto.dart';
import '../utils/product_api_errors.dart';
import '../../domain/entities/add_product_wizard_state.dart';
import '../../domain/entities/staged_product_image.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class AddProductWizardController extends StateNotifier<AddProductWizardState> {
  AddProductWizardController(this._repository)
      : super(const AddProductWizardState());

  final TenantProductRepository _repository;

  @visibleForTesting
  AddProductWizardState get wizardState => state;

  @visibleForTesting
  void initializeOptions(TenantProductCreateOptions options) {
    state = state.copyWith(createOptions: options);
  }

  void clearPageError() {
    state = state.copyWith(clearPageError: true);
  }

  Future<void> initWizard({String? resumeProductId}) async {
    state = state.copyWith(isLoadingOptions: true, clearOptionsError: true);

    try {
      final options = await _repository.getCreateOptions();
      state = state.copyWith(createOptions: options, isLoadingOptions: false);

      if (resumeProductId != null && resumeProductId.isNotEmpty) {
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

  // --- WIZARD LIFECYCLE: SAVE DRAFT & SAVE AND CONTINUE ---

  Future<bool> saveDraft() async {
    state = state.copyWith(isSavingDraft: true, clearPageError: true);

    final request = SaveProductDraftRequestDto(
      productName:
          state.productName.trim().isEmpty ? null : state.productName.trim(),
      productCode:
          state.internalCode.trim().isEmpty ? null : state.internalCode.trim(),
      categoryId: state.categoryId,
      brandId: state.brandId,
      shortDescription: state.shortDescription.trim().isEmpty
          ? null
          : state.shortDescription.trim(),
      longDescription: state.longDescription.trim().isEmpty
          ? null
          : state.longDescription.trim(),
      desiredPublishActive: state.desiredPublishActive,
      posSellable: state.posSellable,
      trackInventory: state.trackInventory,
      allowOnlineSale: state.allowOnlineSale,
      productStructure: state.productStructure,
      batchTracking: state.batchTracking,
      expiryTracking: state.expiryTracking,
      serialTracking: state.serialTracking,
      currentSetupStep: state.currentStep,
      advanceStep: false,
      wizardAction: 'SAVE_DRAFT',
      expectedRowVersion: state.isEditMode ? state.rowVersion : null,
      stagedMediaAssetIds:
          state.stagedMediaAssets.map((e) => e.mediaAssetId).toList(),
      unitModel: state.unitModel,
      productUnitId: state.productUnitId ?? state.baseUnitId,
      baseUnitId: state.baseUnitId ?? state.productUnitId,
      sellingUnitId: state.sellingUnitId,
      purchaseUnitId: state.purchaseUnitId,
      outerPackUnitId: state.outerPackUnitId,
      itemsPerPurchaseUnit: state.itemsPerPurchaseUnit,
      purchaseUnitsPerOuterPack: state.purchaseUnitsPerOuterPack,
      allowDecimalQuantity: state.allowDecimalQuantity,
    );

    try {
      final ProductDraftResponseDto response;
      if (state.productId != null && state.productId!.isNotEmpty) {
        response = await _repository.updateDraft(state.productId!, request);
      } else {
        response = await _repository.saveDraft(request);
      }

      _hydrateFromDraftResponse(response);
      state = state.copyWith(
        isSavingDraft: false,
        isDirty: false,
      );
      return true;
    } catch (e) {
      final rawErrorMsg = _extractErrorMessage(e);
      final displayError = (rawErrorMsg == 'An unexpected error occurred.' ||
              rawErrorMsg.toLowerCase().contains('unexpected error'))
          ? 'An error occurred while saving draft. Please verify form details and retry.'
          : rawErrorMsg;
      state = state.copyWith(
        isSavingDraft: false,
        pageError: 'Save Draft failed: $displayError',
      );
      return false;
    }
  }

  Future<bool> saveAndContinue() async {
    // Validate Step 1 rules: Product Name & Category required
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

    if (errors.isNotEmpty) {
      state = state.copyWith(
        fieldErrors: errors,
        pageError: 'Please fix validation errors before continuing.',
      );
      return false;
    }

    state = state.copyWith(
        isSubmitting: true, clearPageError: true, fieldErrors: const {});

    final request = SaveProductDraftRequestDto(
      productName: trimmedName,
      productCode:
          state.internalCode.trim().isEmpty ? null : state.internalCode.trim(),
      categoryId: state.categoryId,
      brandId: state.brandId,
      shortDescription: state.shortDescription.trim().isEmpty
          ? null
          : state.shortDescription.trim(),
      longDescription: state.longDescription.trim().isEmpty
          ? null
          : state.longDescription.trim(),
      desiredPublishActive: state.desiredPublishActive,
      posSellable: state.posSellable,
      trackInventory: state.trackInventory,
      allowOnlineSale: state.allowOnlineSale,
      productStructure: state.productStructure,
      batchTracking: state.batchTracking,
      expiryTracking: state.expiryTracking,
      serialTracking: state.serialTracking,
      currentSetupStep: state.currentStep,
      advanceStep: true,
      wizardAction:
          state.currentStep == 8 ? 'CREATE_PRODUCT' : 'SAVE_AND_CONTINUE',
      expectedRowVersion: state.isEditMode ? state.rowVersion : null,
      stagedMediaAssetIds:
          state.stagedMediaAssets.map((e) => e.mediaAssetId).toList(),
      unitModel: state.unitModel,
      productUnitId: state.productUnitId ?? state.baseUnitId,
      baseUnitId: state.baseUnitId ?? state.productUnitId,
      sellingUnitId: state.sellingUnitId,
      purchaseUnitId: state.purchaseUnitId,
      outerPackUnitId: state.outerPackUnitId,
      itemsPerPurchaseUnit: state.itemsPerPurchaseUnit,
      purchaseUnitsPerOuterPack: state.purchaseUnitsPerOuterPack,
      allowDecimalQuantity: state.allowDecimalQuantity,
    );

    try {
      final ProductDraftResponseDto response;
      if (state.productId != null && state.productId!.isNotEmpty) {
        response = await _repository.updateDraft(state.productId!, request);
      } else {
        response = await _repository.saveDraft(request);
      }

      final initialStep = state.currentStep;
      _hydrateFromDraftResponse(response);
      final targetStep = response.targetSetupStep ??
          (response.currentSetupStep > initialStep
              ? response.currentSetupStep
              : (initialStep + 1).clamp(1, 8));

      state = state.copyWith(
        currentStep: targetStep,
        isSubmitting: false,
        isDirty: false,
      );
      return true;
    } catch (e) {
      final extractedErrors =
          e is DioException ? productValidationErrors(e) : <String, String>{};
      final rawErrorMsg = _extractErrorMessage(e);
      final displayError = (rawErrorMsg == 'An unexpected error occurred.' ||
              rawErrorMsg.toLowerCase().contains('unexpected error'))
          ? (extractedErrors.isNotEmpty
              ? extractedErrors.values.join(' ')
              : 'Save failed. Raw Error: $rawErrorMsg | Data: ${e is DioException ? e.response?.data : e.toString()}')
          : 'Save failed. Raw: $rawErrorMsg | Data: ${e is DioException ? e.response?.data : e.toString()}';

      state = state.copyWith(
        isSubmitting: false,
        fieldErrors: extractedErrors,
        pageError: 'Save & Continue failed: $displayError',
      );
      return false;
    }
  }

  Future<bool> skip() async {
    if (state.currentStep == 2 && !state.productStructureConfirmed) {
      state = state.copyWith(
        pageError:
            'Please select a Product Structure before skipping tracking configuration.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearPageError: true,
      fieldErrors: const {},
    );

    final request = SaveProductDraftRequestDto(
      productName:
          state.productName.trim().isEmpty ? null : state.productName.trim(),
      productCode:
          state.internalCode.trim().isEmpty ? null : state.internalCode.trim(),
      categoryId: state.categoryId,
      brandId: state.brandId,
      shortDescription: state.shortDescription.trim().isEmpty
          ? null
          : state.shortDescription.trim(),
      longDescription: state.longDescription.trim().isEmpty
          ? null
          : state.longDescription.trim(),
      desiredPublishActive: state.desiredPublishActive,
      posSellable: state.posSellable,
      trackInventory: state.trackInventory,
      allowOnlineSale: state.allowOnlineSale,
      productStructure: state.productStructure,
      batchTracking: state.batchTracking,
      expiryTracking: state.expiryTracking,
      serialTracking: state.serialTracking,
      currentSetupStep: state.currentStep,
      advanceStep: true,
      wizardAction: 'SKIP',
      expectedRowVersion: state.isEditMode ? state.rowVersion : null,
      stagedMediaAssetIds:
          state.stagedMediaAssets.map((e) => e.mediaAssetId).toList(),
    );

    try {
      final ProductDraftResponseDto response;
      if (state.isEditMode) {
        response = await _repository.updateDraft(state.productId!, request);
      } else {
        response = await _repository.saveDraft(request);
      }

      final initialStep = state.currentStep;
      _hydrateFromDraftResponse(response);
      final targetStep = response.currentSetupStep > initialStep
          ? response.currentSetupStep
          : (initialStep + 1).clamp(1, 8);

      state = state.copyWith(
        currentStep: targetStep,
        isSubmitting: false,
        isDirty: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        pageError: 'Skip failed: ${_extractErrorMessage(e)}',
      );
      return false;
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 8) {
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

  void _hydrateFromDraftResponse(ProductDraftResponseDto draft,
      {int? forceStep}) {
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

    state = state.copyWith(
      productId: draft.productId,
      status: draft.status,
      rowVersion: draft.rowVersion,
      currentStep: resolvedStep,
      targetSetupStep: draft.targetSetupStep,
      lastCompletedSetupStep: draft.lastCompletedSetupStep,
      productName:
          draft.productName == 'Untitled Product' ? '' : draft.productName,
      internalCode: draft.productCode ?? '',
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
}
