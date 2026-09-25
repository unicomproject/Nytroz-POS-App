import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';

import '../../data/dtos/product_draft_response_dto.dart';
import '../../data/dtos/product_setup_scan_dtos.dart';
import '../../data/dtos/opening_stock_draft_dto.dart';
import '../../data/dtos/barcode_sku_dtos.dart';
import '../../data/dtos/pricing_tax_dtos.dart';
import '../../data/mappers/wizard_product_create_mapper.dart';
import '../../domain/entities/add_product_wizard_state.dart';
import '../../domain/entities/product_wizard_capabilities.dart';
import '../../domain/entities/product_wizard_draft.dart';
import '../../domain/entities/scan_barcode_step_state.dart';
import '../../domain/entities/staged_product_image.dart';
import '../../domain/entities/barcode_sku_state.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../../domain/entities/variant_configuration_state.dart';
import '../utils/product_duplicate_helper.dart';
import '../utils/product_form_validation.dart';
import '../utils/barcode_type.dart';
import '../utils/variant_pricing.dart';
import '../../domain/utils/variant_estimated_count_calculator.dart';
import '../../domain/utils/variant_combination_generator.dart';
import '../../domain/repositories/product_wizard_draft_local_repository.dart';
import '../../domain/repositories/tenant_product_repository.dart';
import '../../domain/usecases/get_product_setup.dart';

class AddProductWizardController extends StateNotifier<AddProductWizardState> {
  AddProductWizardController(
    this._repository, {
    ProductWizardDraftLocalRepository? draftLocal,
  })  : _draftLocal = draftLocal,
        super(const AddProductWizardState());

  final TenantProductRepository _repository;
  final ProductWizardDraftLocalRepository? _draftLocal;
  ProductWizardCapabilities? _capabilities;

  @visibleForTesting
  AddProductWizardState get wizardState => state;

  void bindCapabilities(ProductWizardCapabilities capabilities) {
    _capabilities = capabilities;
  }

  @visibleForTesting
  void initializeOptions(TenantProductCreateOptions options) {
    state = state.copyWith(createOptions: options);
  }

  /// Skips Step 1 (Scan Barcode) and advances to Step 2 (Basic Details).
  /// Only for use in unit tests that pre-date the scan step.
  @visibleForTesting
  void skipScanStepForTesting() {
    assert(state.currentStep == 1, 'skipScanStepForTesting called from step ${state.currentStep}');
    state = state.copyWith(currentStep: 2, lastCompletedSetupStep: 1);
  }

  void clearPageError() {
    state = state.copyWith(clearPageError: true);
  }

  Timer? _autoSaveTimer;

  @override
  set state(AddProductWizardState value) {
    super.state = value;
    if (value.isDirty && !value.isSubmitting && !value.isSavingDraft) {
      _triggerAutoSave();
    }
  }

  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _silentSaveDraft();
    });
  }

  Future<void> _silentSaveDraft() async {
    final local = _draftLocal;
    if (local == null) return;

    // Do not auto-save over the generic 'auto_save_draft' if we are editing a live product
    // (i.e., productId is present but it's not a local draft).
    if (state.productId != null &&
        state.productId!.isNotEmpty &&
        state.localDraftId == null) {
      return;
    }

    try {
      final draftId = state.localDraftId ?? 'auto_save_draft';
      final snapshot = state.copyWith(
        localDraftId: draftId,
        status: 'DRAFT',
      );
      final draft = ProductWizardDraft.fromWizardState(
        state: snapshot,
        localDraftId: draftId,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await local.saveDraft(draft);
      if (state.localDraftId == null && mounted) {
        super.state = state.copyWith(localDraftId: draftId);
      }
    } catch (_) {}
  }

  Future<void> discardAutoSave() async {
    _autoSaveTimer?.cancel();
    final local = _draftLocal;
    if (local != null) {
      final draftId = state.localDraftId ?? 'auto_save_draft';
      await local.deleteDraft(draftId);
    }
  }

  /// Reset the wizard to Step 1 after a successful create ("Add Another Product").
  Future<void> startFreshWizard() async {
    await discardAutoSave();
    final options = state.createOptions;
    state = AddProductWizardState(
      createOptions: options,
      currentStep: 1,
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> initWizard({
    String? resumeProductId,
    String? resumeLocalDraftId,
    String? duplicateFromProductId,
  }) async {
    state = state.copyWith(isLoadingOptions: true, clearOptionsError: true);

    try {
      final options = await _repository.getCreateOptions();
      state = state.copyWith(createOptions: options, isLoadingOptions: false);

      if (resumeLocalDraftId != null && resumeLocalDraftId.isNotEmpty) {
        await loadLocalDraft(resumeLocalDraftId);
      } else if (duplicateFromProductId != null &&
          duplicateFromProductId.isNotEmpty) {
        await loadDuplicateFromProduct(duplicateFromProductId);
      } else if (resumeProductId != null && resumeProductId.isNotEmpty) {
        if (state.productId == resumeProductId && state.currentStep > 1) {
          // Draft already hydrated and active in session, preserve step state
        } else {
          await loadExistingDraft(resumeProductId);
        }
      } else if (state.productId == null || state.productId!.isEmpty) {
        final local = _draftLocal;
        if (local != null) {
          final existing = await local.getDraft('auto_save_draft');
          if (existing != null) {
            await loadLocalDraft('auto_save_draft');
            return;
          }
        }
        // Fresh Add Product always starts at Step 1 (Scan Barcode)
        state = state.copyWith(
          currentStep: 1,
          scanStepState: const ScanBarcodeStepState(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingOptions: false,
        optionsError: 'Failed to load product options: ${e.toString()}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Scanner-first Step 1 actions
  // ---------------------------------------------------------------------------

  void backToScan({bool clearValidatedCandidate = true}) {
    if (clearValidatedCandidate) {
      state = state.copyWith(
        currentStep: 1,
        scanStepState: const ScanBarcodeStepState(),
        clearPageError: true,
      );
      return;
    }

    // S1-D Back: return to scan listening but retain validated candidate metadata.
    state = state.copyWith(
      currentStep: 1,
      scanStepState: state.scanStepState.copyWith(
        panel: ScanBarcodePanel.scanReady,
        isBusy: false,
        clearLocalMatch: true,
        clearExternalSuggestion: true,
        clearExternalStatus: true,
        clearLastError: true,
        clearInvalidReason: true,
      ),
      clearPageError: true,
    );
  }

  void backToNoLocalMatch() {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(
        panel: ScanBarcodePanel.noLocalMatch,
        clearExternalSuggestion: true,
        clearExternalStatus: true,
        clearLastError: true,
        isBusy: false,
      ),
    );
  }

  void openManualBarcodeEntry() {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(
        panel: ScanBarcodePanel.manualEntry,
        inputMode: 'MANUAL',
        clearInvalidReason: true,
        clearLastError: true,
        isBusy: false,
      ),
    );
  }

  void updateManualBarcodeDraft(String value) {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(candidateBarcode: value),
    );
  }

  Future<void> validateManualBarcode() async {
    await submitScanCandidate(
      state.scanStepState.candidateBarcode,
      inputMode: 'MANUAL',
    );
  }

  void openNoBarcodeFlow() {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(
        panel: ScanBarcodePanel.noBarcode,
        clearLastError: true,
        isBusy: false,
      ),
    );
    if (state.scanStepState.autoGenerateSku) {
      // Fire-and-forget preview when opening S1-R3 with auto-SKU on.
      unawaited(requestNoBarcodeSkuCandidate());
    }
  }

  void setNoBarcodeCategoryId(String? categoryId) {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(
        noBarcodeCategoryId: categoryId,
        clearNoBarcodeCategoryId: categoryId == null || categoryId.isEmpty,
      ),
      categoryId: categoryId,
      isDirty: true,
    );
  }

  void setNoBarcodeReason(String reason) {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(noBarcodeReason: reason),
    );
  }

  void updateNoBarcodeProductName(String name) {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(noBarcodeProductName: name),
      productName: name,
      isDirty: true,
    );
  }

  Future<void> setAutoGenerateSku(bool enabled) async {
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(autoGenerateSku: enabled),
    );
    if (enabled) {
      await requestNoBarcodeSkuCandidate();
    }
  }

  Future<void> requestNoBarcodeSkuCandidate() async {
    try {
      final result = await _repository.generateSkuCandidate(
        GenerateSkuCandidateRequestDto(
          purpose: 'NO_BARCODE_PRODUCT',
          categoryId: state.categoryId ?? '',
          mode: 'AUTO',
          productId: state.productId,
          expectedRowVersion: state.rowVersion,
        ),
      );
      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          generatedSkuCandidate: result.candidate,
          clearLastError: true,
        ),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          lastError: _dioMessage(e) ?? 'Failed to generate SKU candidate.',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          lastError: e.toString(),
        ),
      );
    }
  }

  Future<void> submitScanCandidate(
    String barcode, {
    String inputMode = 'SCAN',
  }) async {
    final candidate = barcode; // preserve leading zeros as raw string
    if (candidate.trim().isEmpty) {
      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          panel: ScanBarcodePanel.invalid,
          candidateBarcode: candidate,
          invalidReason: 'Barcode is required.',
        ),
      );
      return;
    }

    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(
        panel: ScanBarcodePanel.validating,
        candidateBarcode: candidate,
        inputMode: inputMode,
        isBusy: true,
        clearLastError: true,
        clearInvalidReason: true,
        clearLocalMatch: true,
      ),
    );

    try {
      final response = await _repository.resolveBarcode(
        ResolveProductBarcodeRequestDto(
          barcode: candidate,
          inputMode: inputMode,
        ),
      );

      if (response.isInvalid) {
        // The user explicitly requested to treat invalid barcodes (e.g., checksum failures) 
        // as "Product not found" so they can continue and use them anyway.
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.noLocalMatch,
            candidateBarcode: response.normalizedBarcode ?? candidate,
            identifierStandard: response.identifierStandard,
            barcodeType: response.barcodeType,
            isBusy: false,
          ),
        );
        runExternalLookup();
        return;
      }

      final normalized = response.normalizedBarcode ?? candidate;
      if (response.isValidLocalMatch) {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.localMatch,
            candidateBarcode: normalized,
            identifierStandard: response.identifierStandard,
            barcodeType: response.barcodeType,
            localMatch: response.localMatch,
            isBusy: false,
          ),
        );
        return;
      }

      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          panel: ScanBarcodePanel.noLocalMatch,
          candidateBarcode: normalized,
          identifierStandard: response.identifierStandard,
          barcodeType: response.barcodeType,
          isBusy: false,
        ),
      );

      runExternalLookup();
    } on DioException catch (e) {
      final msg = _dioMessage(e) ?? 'Barcode resolve failed. Try again.';
      if (msg.toLowerCase().contains('invalid') || msg.toLowerCase().contains('identifier') || msg.toLowerCase().contains('format')) {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.externalNoMatch,
            candidateBarcode: candidate,
            clearExternalSuggestion: true,
            isBusy: false,
            clearLastError: true,
          ),
        );
      } else {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.noLocalMatch,
            lastError: msg,
            isBusy: false,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('invalid') || msg.toLowerCase().contains('identifier') || msg.toLowerCase().contains('format')) {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.externalNoMatch,
            candidateBarcode: candidate,
            clearExternalSuggestion: true,
            isBusy: false,
            clearLastError: true,
          ),
        );
      } else {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.noLocalMatch,
            lastError: msg,
            isBusy: false,
          ),
        );
      }
    }
  }

  Future<void> runExternalLookup() async {
    final barcode = state.scanStepState.candidateBarcode;
    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(
        panel: ScanBarcodePanel.externalLookup,
        isBusy: true,
        clearLastError: true,
      ),
    );

    try {
      final response = await _repository.externalLookupBarcode(
        barcode: barcode,
        identifierStandard: state.scanStepState.identifierStandard,
      );

      if (response.isFound) {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.externalFound,
            externalStatus: response.status,
            externalSuggestion: response.suggestion,
            externalSourceReference: response.sourceReference,
            externalRetryAllowed: response.retryAllowed,
            isBusy: false,
          ),
        );
        return;
      }

      if (response.isTemporaryFailure) {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.noLocalMatch,
            externalStatus: response.status,
            externalRetryAllowed: response.retryAllowed,
            lastError: 'External lookup temporarily unavailable. You can retry or continue manually.',
            isBusy: false,
          ),
        );
        return;
      }

      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          panel: ScanBarcodePanel.externalNoMatch,
          externalStatus: response.status,
          externalRetryAllowed: response.retryAllowed,
          clearExternalSuggestion: true,
          isBusy: false,
        ),
      );
    } on DioException catch (e) {
      final msg = _dioMessage(e) ?? 'External lookup failed.';
      if (msg.toLowerCase().contains('invalid') || msg.toLowerCase().contains('identifier') || msg.toLowerCase().contains('format')) {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.externalNoMatch,
            clearExternalSuggestion: true,
            isBusy: false,
            clearLastError: true,
          ),
        );
      } else {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.noLocalMatch,
            lastError: msg,
            isBusy: false,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('invalid') || msg.toLowerCase().contains('identifier') || msg.toLowerCase().contains('format')) {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.externalNoMatch,
            clearExternalSuggestion: true,
            isBusy: false,
            clearLastError: true,
          ),
        );
      } else {
        state = state.copyWith(
          scanStepState: state.scanStepState.copyWith(
            panel: ScanBarcodePanel.noLocalMatch,
            lastError: msg,
            isBusy: false,
          ),
        );
      }
    }
  }

  Future<void> continueUseThisProduct() async {
    await _bootstrapDraft(
      acquisitionMode: state.scanStepState.inputMode == 'MANUAL' ? 'MANUAL' : 'SCAN',
      creationAction: 'USE_THIS_PRODUCT',
      applyExternalPrefill: true,
      externalLookupStatus: 'FOUND',
      normalizedPrefill: state.scanStepState.externalSuggestion,
      externalSourceReference: state.scanStepState.externalSourceReference,
    );
  }

  Future<void> continueCreateManually({required bool applyExternalPrefill}) async {
    await _bootstrapDraft(
      acquisitionMode: state.scanStepState.inputMode == 'MANUAL' ? 'MANUAL' : 'SCAN',
      creationAction: 'CREATE_MANUALLY',
      applyExternalPrefill: false,
      externalLookupStatus: state.scanStepState.externalStatus,
      normalizedPrefill: null,
      externalSourceReference: state.scanStepState.externalSourceReference,
      // No product found externally — Step 2 must be blank; never carry state name.
      suppressStateProductName: true,
    );
  }

  Future<void> continueWithBarcode() async {
    await _bootstrapDraft(
      acquisitionMode: state.scanStepState.inputMode == 'MANUAL' ? 'MANUAL' : 'SCAN',
      creationAction: 'CONTINUE_WITH_BARCODE',
      applyExternalPrefill: false,
      externalLookupStatus: state.scanStepState.externalStatus ?? 'NO_MATCH',
      // No product found externally — Step 2 must be blank; never carry state name.
      suppressStateProductName: true,
    );
  }

  Future<void> continueNoBarcodeBootstrap() async {
    final reason = state.scanStepState.noBarcodeReason;
    final name = state.scanStepState.noBarcodeProductName.trim();
    if (reason == null || reason.isEmpty) {
      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          lastError: 'Select a no-barcode reason.',
        ),
      );
      return;
    }
    if (name.isEmpty) {
      state = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          lastError: 'Product Name is required.',
        ),
      );
      return;
    }
    if (state.scanStepState.autoGenerateSku &&
        (state.scanStepState.generatedSkuCandidate ?? '').isEmpty) {
      await requestNoBarcodeSkuCandidate();
    }

    await _bootstrapDraft(
      acquisitionMode: 'NO_BARCODE',
      creationAction: 'CONTINUE_TO_BASIC_DETAILS',
      applyExternalPrefill: false,
      noBarcodeReason: reason,
      productNameOverride: name,
      generatedSkuCandidate: state.scanStepState.generatedSkuCandidate,
      includeCandidate: false,
    );
  }

  Future<void> _bootstrapDraft({
    required String acquisitionMode,
    required String creationAction,
    required bool applyExternalPrefill,
    String? externalLookupStatus,
    ExternalProductSuggestionDto? normalizedPrefill,
    String? externalSourceReference,
    String? noBarcodeReason,
    String? productNameOverride,
    String? generatedSkuCandidate,
    bool includeCandidate = true,
    bool suppressStateProductName = false,
  }) async {
    if (state.scanStepState.isBusy) return;

    state = state.copyWith(
      scanStepState: state.scanStepState.copyWith(isBusy: true, clearLastError: true),
      isSavingDraft: true,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final scan = state.scanStepState;
      final prefill = applyExternalPrefill ? normalizedPrefill : null;
      
      final productName = productNameOverride ??
            prefill?.productName ??
            (suppressStateProductName || state.productName.isEmpty
                ? null
                : state.productName);

      _applyLocalBootstrap(
        productName: productName,
        prefill: prefill,
        generatedSkuCandidate: generatedSkuCandidate,
        candidateBarcode: includeCandidate ? scan.candidateBarcode : null,
        barcodeType: includeCandidate ? scan.barcodeType : null,
      );
    } catch (e) {
      state = state.copyWith(
        isSavingDraft: false,
        scanStepState: state.scanStepState.copyWith(
          isBusy: false,
          lastError: e.toString(),
        ),
      );
    }
  }

  void _applyLocalBootstrap({
    String? productName,
    ExternalProductSuggestionDto? prefill,
    String? generatedSkuCandidate,
    String? candidateBarcode,
    String? barcodeType,
  }) {
    var next = state.copyWith(
      currentStep: 2,
      targetSetupStep: 2,
      lastCompletedSetupStep: 1,
      productName: productName ?? '',
      shortDescription: prefill?.shortDescription ?? state.shortDescription,
      longDescription: prefill?.longDescription ?? state.longDescription,
      internalCode: state.internalCode,
      isDirty: true,
      isSavingDraft: false,
      scanStepState: state.scanStepState.copyWith(
        isBusy: false,
      ),
    );

    if (prefill != null) {
      final images = <ProductWizardImageItem>[];
      if ((prefill.imageCandidate ?? '').isNotEmpty) {
        images.add(
          ProductWizardImageItem(
            id: 'prefill-image',
            imageUrl: prefill.imageCandidate!,
            fileName: 'External Image',
            isPrimary: true,
            sortOrder: 0,
            isStaged: false,
          ),
        );
      }
      next = next.copyWith(
        productImages: images,
        primaryImageId: images.isNotEmpty ? 'prefill-image' : null,
        clearPrimaryImageId: images.isEmpty,
      );
    }

    if ((generatedSkuCandidate ?? '').isNotEmpty) {
      next = next.copyWith(
        step5State: next.step5State.copyWith(baseSku: generatedSkuCandidate),
      );
    }

    // Seed Step 5 optional barcode from Step 1 candidate (not auto-final until Step 5 save).
    if ((candidateBarcode ?? '').trim().isNotEmpty &&
        next.step5State.parentProductBarcode.trim().isEmpty) {
      next = next.copyWith(
        step5State: next.step5State.copyWith(
          parentProductBarcode: candidateBarcode!,
          parentBarcodeType: barcodeType,
        ),
      );
    }

    state = next;
  }

  String? _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is Map && data['error'] is Map && data['error']['message'] != null) {
      return data['error']['message'].toString();
    }
    return e.message;
  }

  // ---------------------------------------------------------------------------
  // End scanner-first Step 1
  // ---------------------------------------------------------------------------

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
    for (var s = requestedStep + 1; s <= 6; s++) {
      if (isStepApplicable(s)) return s;
    }
    return 1;
  }

  Future<void> loadExistingDraft(String productId) async {
    state = state.copyWith(isSubmitting: true, clearPageError: true);

    try {
      final draft = await GetProductSetup(_repository)(productId);
      _hydrateFromDraftResponse(draft, forceStep: draft.currentSetupStep);
      state = state.copyWith(isSubmitting: false, isDirty: false);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        pageError: 'Failed to load draft: ${_extractErrorMessage(e)}',
      );
    }
  }

  /// Reloads only the images from the backend draft to preserve unsaved local state
  Future<void> _reloadImagesForEditMode(String productId) async {
    try {
      final draft = await GetProductSetup(_repository)(productId);
      _hydrateImagesFromDraftResponse(draft);
    } catch (e) {
      state = state.copyWith(
        pageError: 'Failed to refresh images: ${_extractErrorMessage(e)}',
      );
    }
  }

  /// Hydrates only image-related state from a draft response
  void _hydrateImagesFromDraftResponse(ProductDraftResponseDto draft) {
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

    state = state.copyWith(
      productImages: images,
      primaryImageId: primaryImg.productImageId.isNotEmpty ? primaryImg.productImageId : null,
      clearPrimaryImageId: primaryImg.productImageId.isEmpty,
      isDirty: true,
    );
  }

  /// Loads an existing product's setup data into a fresh wizard for duplication.
  Future<void> loadDuplicateFromProduct(String sourceProductId) async {
    state = state.copyWith(isSubmitting: true, clearPageError: true);

    try {
      // Prefer server NEW DRAFT (cleared SKU/barcode; no stock copy).
      final created = await _repository.duplicateProduct(sourceProductId);
      await loadExistingDraft(created.id);
      state = state.copyWith(
        currentStep: 2,
        isSubmitting: false,
        isDirty: true,
      );
    } catch (_) {
      try {
        final draft = await GetProductSetup(_repository)(sourceProductId);
        _hydrateFromDraftResponse(draft, forceStep: 2);
        _applyDuplicateIdentityReset(sourceProductName: draft.productName);
        state = state.copyWith(isSubmitting: false, isDirty: true);
      } catch (_) {
        try {
          final detail = await _repository.getProductById(sourceProductId);
          _seedFromProductDetail(detail);
          state = state.copyWith(
            currentStep: 2,
            isSubmitting: false,
            isDirty: true,
          );
        } catch (e) {
          state = state.copyWith(
            isSubmitting: false,
            pageError: 'Failed to duplicate product: ${_extractErrorMessage(e)}',
          );
        }
      }
    }
  }

  /// S1-C Create Duplicate — new DRAFT then resume at Step 2.
  Future<void> createDuplicateFromLocalMatch() async {
    final match = state.scanStepState.localMatch;
    if (match == null) return;
    final candidateBarcode = state.scanStepState.candidateBarcode;

    await loadDuplicateFromProduct(match.productId);

    if (candidateBarcode.isNotEmpty) {
      if (state.productStructure.toUpperCase() == 'SIMPLE') {
        state = state.copyWith(
          step5State: state.step5State.copyWith(
            parentProductBarcode: candidateBarcode,
          ),
          isDirty: true,
        );
      }
    }
  }

  void _applyDuplicateIdentityReset({String? sourceProductName}) {
    final clearedAssignments = state.step5State.assignments
        .map(
          (assignment) => assignment.copyWith(
            clearSku: true,
            clearBarcode: true,
            clearProductVariantId: true,
            isAssigned: false,
            clearStatus: true,
          ),
        )
        .toList();

    final clearedVariants = state.step4State.generatedVariants
        .map(
          (variant) => GeneratedVariantRow(
            clientCombinationKey: variant.clientCombinationKey,
            combinationLabel: variant.combinationLabel,
            displayLabel: variant.displayLabel,
            isIncluded: variant.isIncluded,
            exactImageMediaAssetId: variant.exactImageMediaAssetId,
            effectiveImageUrl: variant.effectiveImageUrl,
            selectedValues: variant.selectedValues,
            optionCombinationHash: variant.optionCombinationHash,
          ),
        )
        .toList();

    final stagedAssets = <StagedProductImage>[];
    final duplicatedImages = <ProductWizardImageItem>[];
    for (final image in state.productImages) {
      final mediaAssetId = image.mediaAssetId?.trim();
      if (mediaAssetId == null || mediaAssetId.isEmpty) {
        continue;
      }

      stagedAssets.add(
        StagedProductImage(
          mediaAssetId: mediaAssetId,
          publicUrl: image.imageUrl,
          fileName: image.fileName,
          mimeType: 'image/jpeg',
          fileSizeBytes: 0,
          createdAt: DateTime.now().toUtc(),
          isPrimary: image.isPrimary,
          sortOrder: image.sortOrder,
        ),
      );
      duplicatedImages.add(
        ProductWizardImageItem(
          id: mediaAssetId,
          mediaAssetId: mediaAssetId,
          imageUrl: image.imageUrl,
          fileName: image.fileName,
          isPrimary: image.isPrimary,
          sortOrder: image.sortOrder,
          isStaged: true,
        ),
      );
    }

    String? primaryImageId;
    for (final image in duplicatedImages) {
      if (image.isPrimary) {
        primaryImageId = image.mediaAssetId;
        break;
      }
    }

    state = state.copyWith(
      productId: '',
      clearLocalDraftId: true,
      status: 'DRAFT',
      rowVersion: 0,
      currentStep: 1,
      clearTargetSetupStep: true,
      lastCompletedSetupStep: 0,
      productName: buildDuplicatedProductName(sourceProductName ?? ''),
      internalCode: '',
      desiredPublishActive: false,
      stagedMediaAssets: stagedAssets,
      productImages: duplicatedImages,
      primaryImageId: primaryImageId,
      clearPrimaryImageId: primaryImageId == null,
      step4State: state.step4State.copyWith(
        generatedVariants: clearedVariants,
        deletedVariants: const [],
      ),
      step5State: state.step5State.copyWith(
        baseSku: '',
        parentProductBarcode: '',
        assignments: clearedAssignments,
        clearDuplicateBarcodeConflict: true,
      ),
      isDirty: true,
      clearPageError: true,
      fieldErrors: const {},
    );
  }

  void _seedFromProductDetail(TenantProductDetail detail) {
    final options = state.createOptions;
    final unitId =
        options == null ? null : unitIdForCode(options, detail.unitType);
    final structure = inferProductStructureFromDetail(detail);
    final prevScanState = state.scanStepState;

    state = AddProductWizardState(
      createOptions: options,
      scanStepState: prevScanState,
      currentStep: 1,
      status: 'DRAFT',
      productName: buildDuplicatedProductName(detail.productName),
      internalCode: '',
      categoryId: detail.categoryId,
      brandId: detail.brandId,
      shortDescription: detail.shortDescription ?? '',
      longDescription: detail.longDescription ?? '',
      trackInventory: detail.trackInventory,
      productStructure: structure,
      productStructureConfirmed: true,
      productUnitId: unitId,
      baseUnitId: unitId,
      standardSellingPrice: detail.sellingPrice,
      costPrice: detail.costPrice,
      discountPrice: detail.discountPrice,
      taxId: detail.taxId,
      taxName: detail.taxName,
      posSellable: true,
      allowOnlineSale: true,
      step5State: Step5BarcodeSkuState(
        parentProductBarcode: (structure == 'SIMPLE')
            ? prevScanState.candidateBarcode
            : '',
      ),
      isDirty: true,
    );
  }

  void setProductStructure(String structure) {
    if (structure != 'SIMPLE' &&
        structure != 'VARIANT') {
      return;
    }
    state = state.copyWith(
      productStructure: structure,
      productStructureConfirmed: true,
      isDirty: true,
    );
    if (structure == 'SIMPLE') {
      generateSimpleIdentifiers(overwriteSku: false);
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

  void updateInitialBatchNumber(String val) {
    state = state.copyWith(
      initialBatchNumber: val,
      isDirty: true,
    );
  }

  void updateInitialExpiryDate(DateTime? value) {
    state = state.copyWith(
      initialExpiryDate: value,
      clearInitialExpiryDate: value == null,
      isDirty: true,
    );
  }

  void updateInitialSerialNumber(String val) {
    state = state.copyWith(
      initialSerialNumber: val,
      isDirty: true,
    );
  }

  void updateOpeningStockQuantity(String variantKey, num quantity) {
    final drafts = Map<String, OpeningStockOwnerDraftDto>.from(state.openingStockDrafts);
    final existing = drafts[variantKey];
    if (existing != null) {
      drafts[variantKey] = OpeningStockOwnerDraftDto(
        variantId: existing.variantId,
        openingQuantity: quantity,
        allocations: quantity <= 0 ? [] : existing.allocations,
      );
    } else {
      drafts[variantKey] = OpeningStockOwnerDraftDto(
        openingQuantity: quantity,
        allocations: [],
        variantId: state.productStructure == 'VARIANT' ? null : '', // Can be populated later if needed
      );
    }
    state = state.copyWith(
      openingStockDrafts: drafts,
      isDirty: true,
    );
  }

  void updateOutletAllocation(String variantKey, String outletId, num quantity) {
    final drafts = Map<String, OpeningStockOwnerDraftDto>.from(state.openingStockDrafts);
    final existing = drafts[variantKey] ?? OpeningStockOwnerDraftDto(openingQuantity: 0, allocations: []);
    
    final allocations = List<OutletAllocationDraftDto>.from(existing.allocations);
    final index = allocations.indexWhere((a) => a.outletId == outletId);
    
    // Projected logic
    num otherAllocated = 0;
    for (int i = 0; i < allocations.length; i++) {
      if (i != index) {
        otherAllocated += allocations[i].quantity;
      }
    }
    
    final projected = otherAllocated + quantity;
    if (projected > existing.openingQuantity) {
      // Exceeds max, reject by not updating state
      return;
    }
    
    if (quantity > 0) {
      if (index >= 0) {
        allocations[index] = OutletAllocationDraftDto(outletId: outletId, quantity: quantity);
      } else {
        allocations.add(OutletAllocationDraftDto(outletId: outletId, quantity: quantity));
      }
    } else {
      if (index >= 0) {
        allocations.removeAt(index);
      }
    }
    
    drafts[variantKey] = OpeningStockOwnerDraftDto(
      variantId: existing.variantId,
      openingQuantity: existing.openingQuantity,
      allocations: allocations,
    );
    
    state = state.copyWith(
      openingStockDrafts: drafts,
      isDirty: true,
    );
  }

  void setInitialTrackingAssignedVariantId(String? variantId) {
    state = state.copyWith(
      initialTrackingAssignedVariantId: variantId,
      clearInitialTrackingAssignedVariantId:
          variantId == null || variantId.isEmpty,
      isDirty: true,
    );
  }

  InitialTrackingClearPlan previewTrackingClear({
    String? productStructure,
    bool? trackInventory,
    bool? batchTracking,
    bool? expiryTracking,
    bool? serialTracking,
  }) {
    return InitialTrackingCompatibility.evaluate(
      productStructure: productStructure ?? state.productStructure,
      trackInventory: trackInventory ?? state.trackInventory,
      batchTracking: batchTracking ?? state.batchTracking,
      expiryTracking: expiryTracking ?? state.expiryTracking,
      serialTracking: serialTracking ?? state.serialTracking,
      batch: state.initialBatchNumber,
      expiry: state.initialExpiryDate,
      serial: state.initialSerialNumber,
    );
  }

  void applyInitialTrackingPlan(
    InitialTrackingClearPlan plan, {
    required bool confirmed,
  }) {
    if (plan.requiresConfirmation && !confirmed) {
      return;
    }
    state = state.copyWith(
      initialBatchNumber: plan.batchNumber ?? '',
      initialExpiryDate: plan.expiryDate,
      clearInitialExpiryDate: plan.expiryDate == null,
      initialSerialNumber: plan.serialNumber ?? '',
      confirmClearIncompatibleInitialTracking:
          confirmed && plan.requiresConfirmation,
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

  void toggleTrackInventory(bool val) {
    state = state.copyWith(
      trackInventory: val,
      isDirty: true,
    );
  }

  void toggleSerialTracking(bool val) {
    state = state.copyWith(
      serialTracking: val,
      isDirty: true,
    );
  }

  void toggleBatchExpiryTracking(bool val) {
    state = state.copyWith(
      batchTracking: val,
      expiryTracking: val, // Enable both for this card
      isDirty: true,
    );
  }

  void setTrackingMethod(String method) {
    if (state.trackingMethod == method) return;
    
    // Keep existing tracking details to allow tab switching without data loss
    String initialBatchNumber = state.initialBatchNumber;
    DateTime? initialExpiryDate = state.initialExpiryDate;
    Map<String, OpeningStockOwnerDraftDto> openingStockDrafts = state.openingStockDrafts;
    
    // Legacy flags mapping
    bool trackInventory = method == 'QUANTITY';
    bool batchTracking = method == 'BATCH' || method == 'BATCH_EXPIRY';
    bool expiryTracking = method == 'BATCH_EXPIRY';
    bool serialTracking = false;
    
    state = state.copyWith(
      trackingMethod: method,
      trackingInternalStep: 1, // Reset internal flow
      trackInventory: trackInventory,
      batchTracking: batchTracking,
      expiryTracking: expiryTracking,
      serialTracking: serialTracking,
      initialBatchNumber: initialBatchNumber,
      initialExpiryDate: initialExpiryDate,
      openingStockDrafts: openingStockDrafts,
      isDirty: true,
    );
  }

  // --- LEGACY SETTERS FOR TEST COMPATIBILITY ---
  @Deprecated('Use setTrackingMethod instead')
  void setTrackInventory(bool val) {
    if (!val) {
      state = state.copyWith(
        trackInventory: false,
        batchTracking: false,
        expiryTracking: false,
        serialTracking: false,
        trackingMethod: 'SKIP',
        isDirty: true,
      );
    } else {
      state = state.copyWith(
        trackInventory: true,
        trackingMethod: 'QUANTITY',
        isDirty: true,
      );
    }
  }

  @Deprecated('Use setTrackingMethod instead')
  void setBatchTracking(bool val) {
    if (!state.trackInventory) return;
    if (state.serialTracking && val) return; // Serial and Batch mutually exclusive

    if (!val) {
      state = state.copyWith(
        batchTracking: false,
        expiryTracking: false,
        trackingMethod: 'QUANTITY',
        isDirty: true,
      );
    } else {
      state = state.copyWith(
        batchTracking: true,
        trackingMethod: 'BATCH',
        isDirty: true,
      );
    }
  }

  @Deprecated('Use setTrackingMethod instead')
  void setExpiryTracking(bool val) {
    if (!state.trackInventory) return;
    if (!state.batchTracking && val) return; // Expiry requires Batch
    if (state.serialTracking && val) return; // Serial and Expiry mutually exclusive

    state = state.copyWith(
      expiryTracking: val,
      trackingMethod: val ? 'BATCH_EXPIRY' : 'BATCH',
      isDirty: true,
    );
  }

  @Deprecated('Use setTrackingMethod instead')
  void setSerialTracking(bool val) {
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
  // ---------------------------------------------

  void setTrackingInternalStep(int step) {
    state = state.copyWith(
      trackingInternalStep: step,
    );
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
        // Refresh only the images to avoid wiping unsaved form data
        await _reloadImagesForEditMode(state.productId!);
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
        _hydrateImagesFromDraftResponse(draft);
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
        _hydrateImagesFromDraftResponse(draft);
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
        _hydrateImagesFromDraftResponse(draft);
        state = state.copyWith(isSubmitting: false);
      } catch (e) {
        // Rollback optimistic state
        await _reloadImagesForEditMode(state.productId!);
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

  /// Scanner-first:
  /// SIMPLE/VARIANT: 1→2→3→4→5→6→7
  /// When Track Inventory OFF: skip Unit & Pack (Step 4)
  @visibleForTesting
  int getNextApplicableStep([int? fromStep]) {
    final step = fromStep ?? state.currentStep;
    switch (step) {
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
      case 4:
        return 5;
      case 5:
        return 6;
      default:
        return step.clamp(1, 6);
    }
  }

  @visibleForTesting
  int getPreviousApplicableStep([int? fromStep]) {
    final step = fromStep ?? state.currentStep;
    switch (step) {
      case 6:
        return 5;
      case 5:
        return 4;
      case 4:
        return 3;
      case 3:
        return 2;
      case 2:
        return 1;
      default:
        return step.clamp(1, 6);
    }
  }

  @visibleForTesting
  bool isStepApplicable(int step) {
    if (step < 1 || step > 6) return false;
    return true;
  }

  void goToPreviousApplicableStep() {
    if (state.currentStep == 5 && state.trackingInternalStep > 1) {
      if (state.trackingInternalStep == 4) {
        if (state.trackInventory) {
          setTrackingInternalStep(3);
          return;
        } else {
          setTrackingInternalStep(1);
          return;
        }
      } else if (state.trackingInternalStep == 3) {
        setTrackingInternalStep(2);
        return;
      } else if (state.trackingInternalStep == 2) {
        setTrackingInternalStep(1);
        return;
      }
    }

    final prev = getPreviousApplicableStep();
    if (prev != state.currentStep && prev >= 1) {
      state = state.copyWith(currentStep: prev);
    }
  }

  Future<void> generateVariants() async {
    state = state.copyWith(isSavingDraft: true, clearPageError: true);

    final estimate = VariantEstimatedCountCalculator.calculate(
      state.step4State.attributeRows,
    );
    if (!estimate.isComplete) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError:
            'Add at least one attribute with values before generating variants.',
      );
      return;
    }
    if (estimate.exceedsMaximum) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError:
            'Cartesian matrix produces more than the maximum allowed limit of ${VariantEstimatedCountCalculator.maxVariantCombinationsPerProduct} variants.',
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
    await ensureBaseSku();
    reconcileStep5AssignmentsWithVariants();
    reconcileVariantPricesWithVariants();
    await persistStep3Draft();
  }

  Future<void> ensureBaseSku() async {
    if (state.step5State.baseSku.trim().isNotEmpty) {
      return;
    }

    final categoryId = state.categoryId?.trim();
    if (categoryId == null || categoryId.isEmpty) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError: 'Category is required for automatic SKU generation.',
      );
      return;
    }

    state = state.copyWith(isSavingDraft: true, clearPageError: true);
    try {
      final request = GenerateSkuCandidateRequestDto(
        purpose: 'NO_BARCODE_PRODUCT',
        categoryId: categoryId,
        mode: 'AUTO',
        productId: state.productId,
        expectedRowVersion: state.rowVersion,
      );

      final response = await _repository.generateSkuCandidate(request)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'SKU generation timed out after 30 seconds',
            ),
          );

      if (response.candidate.trim().isEmpty) {
        state = state.copyWith(
          isSavingDraft: false,
          pageError: 'Backend returned empty SKU candidate',
        );
        return;
      }

      if (state.step5State.baseSku.trim().isEmpty) {
        state = state.copyWith(
          step5State: state.step5State.copyWith(baseSku: response.candidate),
          isSavingDraft: false,
          isDirty: true,
        );
      } else {
        state = state.copyWith(
          isSavingDraft: false,
        );
      }
    } on TimeoutException {
      state = state.copyWith(
        isSavingDraft: false,
        pageError: 'SKU generation took too long. Please check your connection and try again.',
      );
    } catch (e) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError: 'Failed to generate base SKU: ${_extractErrorMessage(e)}',
      );
    }
  }

  Future<void> persistStep3Draft() async {
    if (state.categoryId == null || state.categoryId!.isEmpty) {
      return;
    }

    state = state.copyWith(isSavingDraft: true, clearPageError: true);
    try {
      final request = WizardProductCreateMapper.toWizardDraftDto(
        state,
        wizardAction: 'SAVE_DRAFT',
        advanceStep: false,
      );
      
      final response = state.productId != null
          ? await _repository.updateDraft(state.productId!, request)
          : await _repository.saveDraft(request);
      
      // Rehydrate Variant SKUs from response assignments
      if (state.productStructure.toUpperCase() == 'VARIANT') {
        final Map<String, String> resolvedSkus = {};
        final Map<String, String> resolvedVariantIds = {};
        for (final assignment in response.barcodeSkuConfiguration?.assignments ?? []) {
          if (assignment.sku != null && assignment.sku!.isNotEmpty) {
            resolvedSkus[assignment.clientCombinationKey] = assignment.sku!;
          }
          if (assignment.productVariantId != null && assignment.productVariantId!.isNotEmpty) {
            resolvedVariantIds[assignment.clientCombinationKey] = assignment.productVariantId!;
          }
        }

        final assignments = state.step5State.assignments.map((a) {
          final sku = resolvedSkus[a.clientCombinationKey] ?? a.sku;
          final variantId = resolvedVariantIds[a.clientCombinationKey] ?? a.productVariantId;
          return a.copyWith(
            productVariantId: variantId,
            clearProductVariantId: variantId == null,
            sku: sku,
            isAssigned: (sku?.trim().isNotEmpty ?? false) || (a.barcode?.trim().isNotEmpty ?? false),
          );
        }).toList();

        final variants = state.step4State.generatedVariants.map((v) {
          final variantId = resolvedVariantIds[v.clientCombinationKey] ?? v.productVariantId;
          if (variantId != null) {
            return v.copyWith(productVariantId: variantId);
          }
          return v;
        }).toList();

        state = state.copyWith(
          step4State: state.step4State.copyWith(generatedVariants: variants),
          step5State: state.step5State.copyWith(assignments: assignments),
          productId: response.productId,
          rowVersion: response.rowVersion,
          isSavingDraft: false,
          isDirty: false,
        );
      } else {
        state = state.copyWith(
          productId: response.productId,
          rowVersion: response.rowVersion,
          isSavingDraft: false,
          isDirty: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSavingDraft: false,
        pageError: 'Failed to reconcile SKUs: ${_extractErrorMessage(e)}',
      );
    }
  }

  void reconcileStep5AssignmentsWithVariants() {
    if (state.productStructure.toUpperCase() != 'VARIANT') return;

    final included =
        state.step4State.generatedVariants.where((v) => v.isIncluded).toList();
    final existingByKey = <String, BarcodeSkuAssignmentDto>{
      for (final a in state.step5State.assignments) a.clientCombinationKey: a,
    };

    final next = <BarcodeSkuAssignmentDto>[];
    final baseSku = state.step5State.baseSku.trim();
    final autoGenerate = state.scanStepState.autoGenerateSku;

    int index = 1;
    for (final variant in included) {
      final previous = existingByKey[variant.clientCombinationKey];
      var sku = previous?.sku;
      
      if ((sku == null || sku.trim().isEmpty) && autoGenerate && baseSku.isNotEmpty) {
        sku = '$baseSku-${index.toString().padLeft(2, '0')}';
      }

      final barcode = previous?.barcode;
      next.add(
        BarcodeSkuAssignmentDto(
          clientCombinationKey: variant.clientCombinationKey,
          productVariantId:
              previous?.productVariantId ?? variant.productVariantId,
          displayName: variant.displayLabel ?? variant.combinationLabel,
          sku: sku,
          barcode: barcode,
          barcodeType: previous?.barcodeType,
          isAssigned: (sku?.trim().isNotEmpty ?? false) ||
              (barcode?.trim().isNotEmpty ?? false),
          status: previous?.status,
        ),
      );
      index++;
    }

    final selected = state.step5State.selectedClientKeys
        .where((k) => next.any((a) => a.clientCombinationKey == k))
        .toSet();

    state = state.copyWith(
      step5State: state.step5State.copyWith(
        assignments: next,
        selectedClientKeys: selected,
      ),
      isDirty: true,
    );
  }

  void ensureVariantStep5Targets() {
    reconcileStep5AssignmentsWithVariants();
  }

  void toggleStep5RowSelection(String clientCombinationKey) {
    final next = Set<String>.from(state.step5State.selectedClientKeys);
    if (!next.add(clientCombinationKey)) {
      next.remove(clientCombinationKey);
    }
    state = state.copyWith(
      step5State: state.step5State.copyWith(selectedClientKeys: next),
    );
  }

  void clearStep5RowSelection() {
    if (state.step5State.selectedClientKeys.isEmpty) return;
    state = state.copyWith(
      step5State: state.step5State.copyWith(selectedClientKeys: const {}),
    );
  }

  void setStep5SearchQuery(String query) {
    state = state.copyWith(
      step5State: state.step5State.copyWith(searchQuery: query),
    );
  }

  void setStep5StatusFilter(Step5StatusFilter filter) {
    state = state.copyWith(
      step5State: state.step5State.copyWith(statusFilter: filter),
    );
  }

  void updateVariantSku(String clientCombinationKey, String sku) {
    final list =
        List<BarcodeSkuAssignmentDto>.from(state.step5State.assignments);
    final idx =
        list.indexWhere((e) => e.clientCombinationKey == clientCombinationKey);
    if (idx < 0) return;
    final current = list[idx];
    list[idx] = current.copyWith(
      sku: sku,
      clearStatus: true,
      isAssigned: sku.trim().isNotEmpty ||
          (current.barcode?.trim().isNotEmpty ?? false),
    );
    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: list),
      isDirty: true,
    );
  }

  void updateVariantBarcode(String clientCombinationKey, String barcode) {
    final list =
        List<BarcodeSkuAssignmentDto>.from(state.step5State.assignments);
    final idx =
        list.indexWhere((e) => e.clientCombinationKey == clientCombinationKey);
    if (idx < 0) return;
    final current = list[idx];
    final type = resolveBarcodeType(
      barcode: barcode,
      existingType: current.barcodeType,
    );
    list[idx] = current.copyWith(
      barcode: barcode,
      barcodeType: type,
      clearBarcodeType: type == null,
      clearStatus: true,
      isAssigned: (current.sku?.trim().isNotEmpty ?? false) ||
          barcode.trim().isNotEmpty,
    );
    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: list),
      isDirty: true,
    );
  }

  void updateVariantBarcodeType(
      String clientCombinationKey, String barcodeType) {
    final list =
        List<BarcodeSkuAssignmentDto>.from(state.step5State.assignments);
    final idx =
        list.indexWhere((e) => e.clientCombinationKey == clientCombinationKey);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(barcodeType: barcodeType, clearStatus: true);
    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: list),
      isDirty: true,
    );
  }

  void handleBarcodeScanComplete(String clientCombinationKey, String scanned) {
    // One logical edit after HID wedge Enter — not per digit.
    updateVariantBarcode(clientCombinationKey, scanned);
  }

  void clearVariantIdentifierDraft(String clientCombinationKey) {
    final list =
        List<BarcodeSkuAssignmentDto>.from(state.step5State.assignments);
    final idx =
        list.indexWhere((e) => e.clientCombinationKey == clientCombinationKey);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(
      clearSku: true,
      clearBarcode: true,
      clearBarcodeType: true,
      clearStatus: true,
      isAssigned: false,
    );
    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: list),
      isDirty: true,
    );
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
      if (structure == 'SIMPLE') {
        commitSimpleBarcodeSkuToState();
      } else if (structure == 'VARIANT') {
        reconcileStep5AssignmentsWithVariants();
        reconcileVariantPricesWithVariants();
      }

      String draftId = state.localDraftId ?? _newLocalDraftId();
      DateTime? createdAt;

      if (draftId == 'auto_save_draft') {
        draftId = _newLocalDraftId();
        await local.deleteDraft('auto_save_draft');
      } else if (state.localDraftId != null) {
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
    if (structure == 'SIMPLE') {
      commitSimpleBarcodeSkuToState();
    } else if (structure == 'VARIANT') {
      reconcileStep5AssignmentsWithVariants();
      reconcileVariantPricesWithVariants();
    }
    ensureBarcodeTypesResolved();

    final step5Errors = validateStep5Continue();
    final step6Errors = <String, String>{};
    if (structure == 'VARIANT') {
      final rows = buildVariantPricingRows(state: state);
      if (rows.isEmpty || rows.any((r) => !r.isPriced)) {
        step6Errors['variantPrices'] =
            'Enter a selling price for all included variants before creating.';
      }
    } else if (state.standardSellingPrice == null ||
        state.standardSellingPrice! <= 0) {
      step6Errors['standardSellingPrice'] =
          'Standard selling price is required.';
    }


    final errors = {...step5Errors, ...step6Errors};
    if (errors.isNotEmpty) {
      final jumpToBarcodeStep = errors.keys.any(
        (k) =>
            k == 'sku' ||
            k == 'skuDuplicate' ||
            k == 'barcode' ||
            k == 'barcodeType' ||
            k == 'barcodeDuplicate',
      );
      state = state.copyWith(
        fieldErrors: errors,
        pageError: errors.values.first,
        isSubmitting: false,
        currentStep: jumpToBarcodeStep ? 5 : state.currentStep,
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
        capabilities: _capabilities,
      );
      final result = await _repository.createProductFromWizard(payload);

      final draftId = state.localDraftId;
      if (draftId != null && draftId.isNotEmpty && _draftLocal != null) {
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
      // DEBUG: log full response body to find exact 400 cause
      if (e is DioException) {
        debugPrint('=== CREATE PRODUCT ERROR ===');
        debugPrint('Status: ${e.response?.statusCode}');
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('============================');
      }
      final mapped = <String, String>{};
      if (e is DioException && e.response?.data is Map) {
        mapped.addAll(
          mapVariantPriceServerFieldErrors(
            submittedSnapshot: buildVariantPriceSnapshot(state),
            errorBody: e.response!.data,
          ),
        );
      }
      final message = _extractErrorMessage(e);
      
      int? targetStep;
      if (_isBarcodeOrSkuCreateError(message, mapped)) {
        targetStep = 5;
      } else if (_isProductCodeError(message, mapped)) {
        targetStep = 2;
      }

      state = state.copyWith(
        isSubmitting: false,
        pageError: 'Failed to create product: $message',
        fieldErrors: mapped,
        currentStep: targetStep ?? state.currentStep,
      );
      return false;
    }
  }

  /// Validate current step, commit to wizard state, navigate locally.
  /// Step 1 uses dedicated bootstrap actions (not Save & Continue).
  /// Step 7 performs the sole backend Product Create (wizard-create) / publish path.
  Future<bool> saveAndContinue() async {
    if (state.currentStep == 6) {
      return createProductFromWizard();
    }

    final errors = <String, String>{};
    final trimmedName = state.productName.trim();

    // Step 1 — Scan: Save & Continue disabled in UI; no name/category gate here.
    if (state.currentStep == 1) {
      state = state.copyWith(
        pageError:
            'Use Step 1 actions (Use This Product / Create Manually / Continue) to create a draft.',
      );
      return false;
    }

    // Step 2 — Basic Details
    if (state.currentStep == 2) {
      if (trimmedName.isEmpty ||
          trimmedName.toLowerCase() == 'untitled product') {
        errors['productName'] = 'Product name is required.';
      }

      final trimmedCode = state.internalCode.trim();
      if (trimmedCode.isEmpty) {
        errors['productCode'] = 'Product code is required.';
      } else if (trimmedCode.length > 80) {
        errors['productCode'] = 'Product code cannot exceed 80 characters.';
      }

      if (state.categoryId == null || state.categoryId!.isEmpty) {
        errors['categoryId'] = 'Category is required.';
      }
    }

    // Step 3 — Product Type & Configuration
    if (state.currentStep == 3) {
      if (!state.productStructureConfirmed) {
        state = state.copyWith(
          pageError:
              'Please explicitly select a Product Type before continuing.',
        );
        return false;
      }
      
      final step4Errors = validateStep3Continue(); // units validators (legacy name)
      if (step4Errors.isNotEmpty) {
        errors.addAll(step4Errors);
      }
      
      final structure = state.productStructure.toUpperCase();
      if (structure == 'VARIANT') {
        final configErrors = validateStep4Continue(); // variant matrix validators
        if (configErrors.isNotEmpty) {
          errors.addAll(configErrors);
        } else {
          reconcileStep5AssignmentsWithVariants();
          reconcileVariantPricesWithVariants();
        }
      }
      if (structure == 'SIMPLE') {
        if (state.step5State.baseSku.trim().isEmpty) {
          await ensureBaseSku();
        }
        commitSimpleBarcodeSkuToState();
      } else if (structure == 'VARIANT') {
        reconcileStep5AssignmentsWithVariants();
        reconcileVariantPricesWithVariants();
      }
      ensureBarcodeTypesResolved();
      final step5Errors = validateStep5Continue();
      if (step5Errors.isNotEmpty) {
        errors.addAll(step5Errors);
      }
    }

    // Step 4 — Pricing & Tax
    if (state.currentStep == 4) {
      final structure = state.productStructure.toUpperCase();
      if (structure == 'VARIANT') {
        reconcileVariantPricesWithVariants();
        final rows = buildVariantPricingRows(state: state);
        if (rows.isEmpty) {
          errors['variantPrices'] =
              'Include at least one sellable variant before Pricing & Tax.';
        }
        for (final row in rows) {
          if (!row.isPriced) {
            errors['variantPrice:${row.identityKey}'] =
                'Enter a selling price greater than zero.';
          }
        }
        if (rows.any((r) => !r.isPriced)) {
          errors['variantPrices'] =
              'Enter a selling price for all included variants before continuing.';
        }
      } else if (structure == 'SIMPLE') {
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
    }

    // Step 5 — Tracking
    if (state.currentStep == 5) {
      if (!state.trackInventory && !state.batchTracking && !state.expiryTracking && !state.serialTracking) {
        state = state.copyWith(pageError: 'Please select at least one tracking method, or skip tracking.');
        return false;
      }

      if (state.trackingInternalStep == 1) {
        if (state.trackInventory) {
          setTrackingInternalStep(2);
          return false; // Stay on step 5 but internal step 2
        }
        if (state.batchTracking || state.expiryTracking) {
          setTrackingInternalStep(4);
          return false;
        }
      } else if (state.trackingInternalStep == 2) {
        bool hasPositiveOpeningQuantity = false;
        for (final draft in state.openingStockDrafts.values) {
          if (draft.openingQuantity > 0) {
            hasPositiveOpeningQuantity = true;
            break;
          }
        }
        if (hasPositiveOpeningQuantity) {
          setTrackingInternalStep(3);
          return false;
        } else if (state.batchTracking || state.expiryTracking) {
          setTrackingInternalStep(4);
          return false;
        }
      } else if (state.trackingInternalStep == 3) {
        bool isValid = true;
        for (final draft in state.openingStockDrafts.values) {
          final allocated = draft.allocations.fold<num>(0, (sum, a) => sum + a.quantity);
          if (allocated > draft.openingQuantity) {
            isValid = false;
            break;
          }
        }
        if (!isValid) {
          state = state.copyWith(pageError: 'Allocated quantities cannot exceed the opening stock.');
          return false;
        }
        if (state.batchTracking || state.expiryTracking) {
          setTrackingInternalStep(4);
          return false;
        }
      } else if (state.trackingInternalStep == 4) {
        // Validation for BatchTrackingForm if necessary (currently none)
      }
      
      final plan = previewTrackingClear();
      if (plan.requiresConfirmation) {
        applyInitialTrackingPlan(plan, confirmed: true);
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

  bool get canSkipCurrentStep =>
      state.currentStep >= 2 && state.currentStep <= 5;

  /// Skip advances without Save & Continue validation.
  /// Step 3 still requires an explicit Product Type (SIMPLE / VARIANT).
  Future<bool> skip() async {
    if (!canSkipCurrentStep) {
      state = state.copyWith(
        pageError: 'Skip is available on steps 2 to 5 only.',
      );
      return false;
    }

    if (state.currentStep == 3 && !state.productStructureConfirmed) {
      state = state.copyWith(
        pageError:
            'Please select a Product Type before skipping tracking configuration.',
      );
      return false;
    }

    _logBlockedProductMutation('skip(step${state.currentStep})');

    if (state.currentStep == 3) {
      state = state.copyWith(
        trackInventory: false,
        batchTracking: false,
        expiryTracking: false,
        serialTracking: false,
      );
      final plan = previewTrackingClear();
      if (plan.requiresConfirmation) {
        applyInitialTrackingPlan(plan, confirmed: true);
      }
    }
    
    if (state.currentStep == 5) {
      state = state.copyWith(
        trackingMethod: 'SKIP',
        trackInventory: false,
        batchTracking: false,
        expiryTracking: false,
        serialTracking: false,
        trackingInternalStep: 1,
        openingStockDrafts: const {},
      );
    }

    final nextStep = getNextApplicableStep();
    final completed = state.currentStep;

    state = state.copyWith(
      currentStep: nextStep,
      lastCompletedSetupStep: completed,
      targetSetupStep: nextStep,
      isSubmitting: false,
      clearPageError: true,
      fieldErrors: const {},
      isDirty: true,
    );
    return true;
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

    if (state.productStructure.toUpperCase() == 'VARIANT') {
      return errors;
    }

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
            state.purchaseUnitsPerOuterPack! <= 1) {
          errors['purchaseUnitsPerOuterPack'] =
              'Outer pack quantity must be greater than Pack 1.';
        } else if (state.purchaseUnitsPerOuterPack! % 1 != 0) {
          errors['purchaseUnitsPerOuterPack'] =
              'Outer pack quantity must contain a whole number of the first pack.';
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

    final estimate = VariantEstimatedCountCalculator.calculate(
      state.step4State.attributeRows,
    );
    if (!estimate.isComplete && state.step4State.attributeRows.isNotEmpty) {
      errors['variantEstimatedCount'] =
          'Each selected attribute must contain at least one value.';
    } else if (estimate.exceedsMaximum) {
      errors['variantEstimatedCount'] =
          'Cartesian matrix produces more than the maximum allowed limit of ${VariantEstimatedCountCalculator.maxVariantCombinationsPerProduct} variants.';
    }

    final included =
        state.step4State.generatedVariants.where((v) => v.isIncluded).toList();
    if (included.isEmpty) {
      errors['generatedVariants'] =
          'Generate and include at least one variant before continuing.';
    }

    return errors;
  }

  Map<String, String> validateStep5Continue() {
    final errors = <String, String>{};
    final structure = state.productStructure.toUpperCase();

    if (structure == 'SIMPLE') {
      if (state.step5State.baseSku.trim().isEmpty) {
        errors['sku'] = 'Base SKU is required.';
      } else if (state.step5State.baseSku.trim().length > 80) {
        errors['sku'] = 'Base SKU must be 80 characters or fewer.';
      }
      _collectBarcodeFieldError(
        errors,
        barcode: state.step5State.parentProductBarcode,
        barcodeType: state.step5State.parentBarcodeType,
      );
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

      for (final a in activeAssignments) {
        _collectBarcodeFieldError(
          errors,
          barcode: a.barcode,
          barcodeType: a.barcodeType,
        );
        if (errors.containsKey('barcode')) break;
      }
    }

    return errors;
  }

  void _collectBarcodeFieldError(
    Map<String, String> errors, {
    required String? barcode,
    String? barcodeType,
  }) {
    final value = barcode?.trim() ?? '';
    if (value.isEmpty) return;
    final resolved = resolveBarcodeType(
      barcode: value,
      existingType: barcodeType,
    );
    if (resolved == null || resolved.isEmpty) {
      errors['barcode'] =
          'Barcode type is required when a barcode is provided.';
      return;
    }
    final formatError = validateBarcodeFormat(value, resolved);
    if (formatError != null) {
      errors['barcode'] = formatError;
    }
  }

  /// Persist an internal barcode type whenever a barcode is present.
  /// SIMPLE hides the type dropdown; type is still required by the API.
  void ensureBarcodeTypesResolved() {
    final structure = state.productStructure.toUpperCase();
    if (structure == 'SIMPLE') {
      final parentBarcode = state.step5State.parentProductBarcode.trim();
      final assignmentBarcode = state.step5State.assignments
          .where((a) => a.clientCombinationKey == 'SIMPLE_DEFAULT')
          .map((a) => a.barcode?.trim() ?? '')
          .firstWhere((b) => b.isNotEmpty, orElse: () => '');
      final barcode =
          parentBarcode.isNotEmpty ? parentBarcode : assignmentBarcode;
      final existingType = state.step5State.parentBarcodeType ??
          state.step5State.assignments
              .where((a) => a.clientCombinationKey == 'SIMPLE_DEFAULT')
              .map((a) => a.barcodeType)
              .whereType<String>()
              .where((t) => t.trim().isNotEmpty)
              .firstOrNull;
      final type = resolveBarcodeType(
        barcode: barcode,
        existingType: existingType,
      );
      var assignments = state.step5State.assignments;
      if (assignments.isEmpty &&
          (state.step5State.baseSku.trim().isNotEmpty || barcode.isNotEmpty)) {
        assignments = [
          BarcodeSkuAssignmentDto(
            clientCombinationKey: 'SIMPLE_DEFAULT',
            sku: state.step5State.baseSku.trim().isEmpty
                ? null
                : state.step5State.baseSku.trim(),
            barcode: barcode.isEmpty ? null : barcode,
            barcodeType: type,
            isAssigned: true,
          ),
        ];
      } else if (assignments.isNotEmpty) {
        assignments = [
          for (final a in assignments)
            a.clientCombinationKey == 'SIMPLE_DEFAULT'
                ? a.copyWith(
                    barcode: barcode.isEmpty ? null : barcode,
                    clearBarcode: barcode.isEmpty,
                    barcodeType: type,
                    clearBarcodeType: type == null,
                    isAssigned: state.step5State.baseSku.trim().isNotEmpty ||
                        barcode.isNotEmpty,
                  )
                : a,
        ];
      }
      state = state.copyWith(
        step5State: state.step5State.copyWith(
          parentProductBarcode: barcode,
          parentBarcodeType: type,
          clearParentBarcodeType: type == null,
          assignments: assignments,
        ),
      );
      return;
    }

    if (structure != 'VARIANT') return;

    final list =
        List<BarcodeSkuAssignmentDto>.from(state.step5State.assignments);
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      final a = list[i];
      final barcode = a.barcode?.trim() ?? '';
      final type = resolveBarcodeType(
        barcode: barcode,
        existingType: a.barcodeType,
      );
      if (type == a.barcodeType) continue;
      list[i] = a.copyWith(
        barcodeType: type,
        clearBarcodeType: type == null,
      );
      changed = true;
    }
    if (changed) {
      state = state.copyWith(
        step5State: state.step5State.copyWith(assignments: list),
      );
    }
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

    final assignments = draft.barcodeSkuConfiguration?.assignments ??
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
      parentBarcodeType:
          simpleAssignment?.barcodeType ?? state.step5State.parentBarcodeType,
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
      internalCode:
          (draft.productCode != null && draft.productCode!.startsWith('DRF-'))
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
      taxName: draft.pricingTaxConfiguration?.taxName,
      taxRate: draft.pricingTaxConfiguration?.taxRate,
      taxExclusive: draft.pricingTaxConfiguration?.taxExclusive ?? true,
      variantPrices: draft.pricingTaxConfiguration?.variantPrices ?? const [],
      isDirty: keepDirtyStatus ? state.isDirty : false,
    );

    // Resume ScanContext (B9) into Step 1 state + seed Step 5 candidate barcode.
    final ctx = draft.scanContext;
    if (ctx != null) {
      var seeded = state.copyWith(
        scanStepState: state.scanStepState.copyWith(
          candidateBarcode: ctx.candidateIdentifier ?? '',
          identifierStandard: ctx.identifierStandard,
          barcodeType: ctx.symbologyHint,
          noBarcodeReason: ctx.noBarcodeReason,
          generatedSkuCandidate: ctx.generatedSkuCandidate,
          externalStatus: ctx.externalLookupStatus,
          externalSourceReference: ctx.externalSourceReference,
          externalSuggestion: ctx.normalizedPrefill,
        ),
      );
      final ctxBarcode = ctx.candidateIdentifier;
      if ((ctxBarcode ?? '').trim().isNotEmpty &&
          seeded.step5State.parentProductBarcode.trim().isEmpty) {
        seeded = seeded.copyWith(
          step5State: seeded.step5State.copyWith(
            parentProductBarcode: ctxBarcode,
            parentBarcodeType: ctx.symbologyHint,
          ),
        );
      }
      if ((ctx.generatedSkuCandidate ?? '').isNotEmpty &&
          seeded.step5State.baseSku.trim().isEmpty) {
        seeded = seeded.copyWith(
          step5State:
              seeded.step5State.copyWith(baseSku: ctx.generatedSkuCandidate),
        );
      }
      state = seeded;
    }
  }

  bool _isBarcodeOrSkuCreateError(
    String message,
    Map<String, String> mapped,
  ) {
    if (mapped.keys.any((k) {
      final key = k.toLowerCase();
      return key.contains('barcode') || key == 'sku' || key.contains('sku');
    })) {
      return true;
    }
    final lower = message.toLowerCase();
    return lower.contains('barcode') || lower.contains('sku');
  }

  bool _isProductCodeError(
    String message,
    Map<String, String> mapped,
  ) {
    if (mapped.keys.any((k) {
      final key = k.toLowerCase();
      return key.contains('productcode') || key.contains('internalcode');
    })) {
      return true;
    }
    final lower = message.toLowerCase();
    return lower.contains('product code');
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

  void reorderAttributeRows(int oldIndex, int newIndex) {
    final rows = List<AttributeConfigRow>.from(state.step4State.attributeRows);
    if (oldIndex < 0 ||
        oldIndex >= rows.length ||
        newIndex < 0 ||
        newIndex >= rows.length ||
        oldIndex == newIndex) {
      return;
    }

    final item = rows.removeAt(oldIndex);
    rows.insert(newIndex, item);
    state = state.copyWith(
      step4State: state.step4State.copyWith(attributeRows: rows),
      isDirty: true,
    );
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

  /// Applies a variant image to either the current variant or all variants
  /// that share [groupValueId] (e.g. all "Blue" color variants).
  Future<bool> applyVariantImage({
    required String variantKey,
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    required String applyScope,
    String? groupValueId,
  }) async {
    if (bytes.length > 5242880) {
      state = state.copyWith(
        pageError: 'Image file size exceeds maximum limit of 5MB.',
      );
      return false;
    }

    state = state.copyWith(clearPageError: true);

    try {
      final staged = await _repository.stageImage(bytes, fileName, mimeType);
      final mediaAssetId = staged.mediaAssetId;
      final imageUrl = staged.publicUrl;

      final variants =
          List<GeneratedVariantRow>.from(state.step4State.generatedVariants);

      bool matchesTarget(GeneratedVariantRow variant) {
        if (applyScope == 'ALL_GROUP' &&
            groupValueId != null &&
            groupValueId.trim().isNotEmpty) {
          return variant.selectedValues
              .any((value) => value.valueId == groupValueId);
        }
        return variant.clientCombinationKey == variantKey;
      }

      for (var i = 0; i < variants.length; i++) {
        if (!matchesTarget(variants[i])) continue;
        variants[i] = variants[i].copyWith(
          exactImageMediaAssetId: mediaAssetId,
          effectiveImageUrl: imageUrl,
        );
      }

      state = state.copyWith(
        step4State: state.step4State.copyWith(generatedVariants: variants),
        isDirty: true,
        clearPageError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        pageError: 'Variant image upload failed: ${_extractErrorMessage(e)}',
      );
      return false;
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
      final template =
          (templates != null && templates.isNotEmpty) ? templates.first : null;
      final templateName = opt.optionName ?? template?.name ?? '';

      // Fallback templateId to optionName if source template is empty
      final tId = (opt.sourceOptionTemplateId.isNotEmpty)
          ? opt.sourceOptionTemplateId
          : (opt.optionName ?? '');

      return AttributeConfigRow(
        templateId: tId.isNotEmpty ? tId : null,
        templateName: templateName,
        selectedValues: opt.values.map((v) {
          final vId = (v.sourceOptionTemplateValueId.isNotEmpty)
              ? v.sourceOptionTemplateValueId
              : (v.valueName ?? '');
          return SelectedOptionValue(
            valueId: vId,
            templateId: tId.isNotEmpty ? tId : null,
            valueName: v.valueName ?? vId,
          );
        }).toList(),
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
        selectedValues: v.selectedValues.map((sv) {
          final tId = sv.sourceOptionTemplateId.isNotEmpty
              ? sv.sourceOptionTemplateId
              : sv.optionName;
          final vId = sv.sourceOptionTemplateValueId.isNotEmpty
              ? sv.sourceOptionTemplateValueId
              : sv.valueName;

          return SelectedOptionValue(
            valueId: vId ?? '',
            templateId: tId,
            valueName: sv.valueName ?? vId ?? '',
          );
        }).toList(),
      );
    }).toList();

    final deleted = dto.deletedCombinations.map((d) {
      return DeletedVariantTombstone(
        clientCombinationKey: d.clientCombinationKey,
        productVariantId: d.productVariantId,
        optionCombinationHash: d.optionCombinationHash,
        selectedValues: d.selectedValues.map((sv) {
          final tId = sv.sourceOptionTemplateId.isNotEmpty
              ? sv.sourceOptionTemplateId
              : sv.optionName;
          final vId = sv.sourceOptionTemplateValueId.isNotEmpty
              ? sv.sourceOptionTemplateValueId
              : sv.valueName;
          return SelectedOptionValue(
            valueId: vId ?? '',
            templateId: tId,
            valueName: sv.valueName ?? vId ?? '',
          );
        }).toList(),
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
      
    List<VariantPriceDto>? updatedVariants;
    if (state.productStructure.toUpperCase() == 'VARIANT' && state.applySameTaxToAllVariants) {
      updatedVariants = state.variantPrices.map((p) {
        return p.copyWith(
          taxId: taxId,
          clearTaxId: taxId == null,
          taxName: taxName,
          clearTaxName: taxId == null,
          taxRate: taxRate,
          clearTaxRate: taxRate == null && taxId == null,
        );
      }).toList();
    }
    
    state = state.copyWith(
      taxId: taxId,
      clearTaxId: taxId == null,
      taxName: taxName,
      clearTaxName: taxId == null,
      taxRate: taxRate,
      clearTaxRate: taxRate == null && taxId == null,
      variantPrices: updatedVariants,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }
  
  void updateApplySameTaxToAllVariants(bool value) {
    if (state.applySameTaxToAllVariants == value) return;
    List<VariantPriceDto>? updatedVariants;
    if (value) {
      // Switched ON: apply global tax to all variants
      updatedVariants = state.variantPrices.map((p) {
        return p.copyWith(
          taxId: state.taxId,
          clearTaxId: state.taxId == null,
          taxName: state.taxName,
          clearTaxName: state.taxId == null,
          taxRate: state.taxRate,
          clearTaxRate: state.taxRate == null && state.taxId == null,
        );
      }).toList();
    }
    state = state.copyWith(
      applySameTaxToAllVariants: value,
      variantPrices: updatedVariants,
      isDirty: true,
    );
  }
  
  void updateVariantTaxId(String identityKey, String? taxId, {num? taxRate, String? taxName}) {
    final index = state.variantPrices.indexWhere((p) => p.identityKey == identityKey);
    if (index == -1) return;

    final updated = List<VariantPriceDto>.from(state.variantPrices);
    updated[index] = updated[index].copyWith(
      taxId: taxId,
      clearTaxId: taxId == null,
      taxName: taxName,
      clearTaxName: taxId == null,
      taxRate: taxRate,
      clearTaxRate: taxRate == null && taxId == null,
    );

    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..remove('variantPrice:$identityKey');

    state = state.copyWith(
      variantPrices: updated,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateTaxExclusive(bool isExclusive) {
    state = state.copyWith(
      taxExclusive: isExclusive,
      isDirty: true,
    );
  }

  /// Aligns Step 6 variant prices to current included Step 4 variants.
  void reconcileVariantPricesWithVariants() {
    if (state.productStructure.toUpperCase() != 'VARIANT') return;
    final included =
        state.step4State.generatedVariants.where((v) => v.isIncluded).toList();
    final next = reconcileVariantPricesWithIncluded(
      includedVariants: included,
      existingPrices: state.variantPrices,
    );
    state = state.copyWith(variantPrices: next);
  }

  void updateVariantSellingPrice({
    required String clientCombinationKey,
    String? productVariantId,
    num? sellingPrice,
  }) {
    reconcileVariantPricesWithVariants();
    final next = state.variantPrices.map((p) {
      final idMatch = productVariantId != null &&
          productVariantId.isNotEmpty &&
          p.productVariantId == productVariantId;
      final keyMatch = p.clientCombinationKey == clientCombinationKey;
      if (!idMatch && !keyMatch) return p;
      return p.copyWith(
        productVariantId: productVariantId ?? p.productVariantId,
        sellingPrice: sellingPrice,
        clearSellingPrice: sellingPrice == null,
      );
    }).toList();

    final updatedErrors = Map<String, String>.from(state.fieldErrors);
    final identity = (productVariantId != null && productVariantId.isNotEmpty)
        ? 'id:$productVariantId'
        : 'key:$clientCombinationKey';
    updatedErrors.remove('variantPrice:$identity');
    updatedErrors.remove('variantPrices');

    state = state.copyWith(
      variantPrices: next,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void updateVariantCostPrice({
    required String clientCombinationKey,
    String? productVariantId,
    num? costPrice,
  }) {
    reconcileVariantPricesWithVariants();
    final next = state.variantPrices.map((p) {
      final idMatch = productVariantId != null &&
          productVariantId.isNotEmpty &&
          p.productVariantId == productVariantId;
      final keyMatch = p.clientCombinationKey == clientCombinationKey;
      if (!idMatch && !keyMatch) return p;
      return p.copyWith(
        productVariantId: productVariantId ?? p.productVariantId,
        costPrice: costPrice,
        clearCostPrice: costPrice == null,
      );
    }).toList();

    state = state.copyWith(
      variantPrices: next,
      isDirty: true,
    );
  }

  void applyBulkSellingPriceToAllVariants(num price) {
    if (price <= 0) return;
    reconcileVariantPricesWithVariants();
    final next = state.variantPrices
        .map((p) => p.copyWith(sellingPrice: price))
        .toList();
    final updatedErrors = Map<String, String>.from(state.fieldErrors)
      ..removeWhere(
        (k, _) => k.startsWith('variantPrice:') || k == 'variantPrices',
      );
    state = state.copyWith(
      variantPrices: next,
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  void applyBulkCostPriceToAllVariants(num price) {
    if (price < 0) return;
    reconcileVariantPricesWithVariants();
    final next = state.variantPrices
        .map((p) => p.copyWith(costPrice: price))
        .toList();
    state = state.copyWith(
      variantPrices: next,
      isDirty: true,
    );
  }

  /// Legacy alias — prefer [applyBulkSellingPriceToAllVariants].
  void applyDefaultSellingPriceToAllVariants(num price) =>
      applyBulkSellingPriceToAllVariants(price);

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
    final type = resolveBarcodeType(
      barcode: barcode,
      existingType: state.step5State.parentBarcodeType,
    );
    state = state.copyWith(
      step5State: state.step5State.copyWith(
        parentProductBarcode: barcode,
        parentBarcodeType: type,
        clearParentBarcodeType: type == null,
      ),
      isDirty: true,
      fieldErrors: updatedErrors,
    );
  }

  /// Explicit Generate action for SIMPLE
  Future<void> generateSimpleIdentifiers({bool overwriteSku = true}) async {
    final existingSku = state.step5State.baseSku.trim();
    if (!overwriteSku && existingSku.isNotEmpty) {
      state = state.copyWith(
        clearPageError: true,
        isDirty: true,
        fieldErrors: Map<String, String>.from(state.fieldErrors)..remove('sku'),
      );
      return;
    }

    await ensureBaseSku();
  }

  /// Commits SIMPLE SKU/barcode into the shared assignment projection (still no variant id).
  void commitSimpleBarcodeSkuToState() {
    final sku = state.step5State.baseSku.trim();
    final barcode = state.step5State.parentProductBarcode.trim();
    final type = resolveBarcodeType(
      barcode: barcode,
      existingType: state.step5State.parentBarcodeType,
    );
    final assignment = BarcodeSkuAssignmentDto(
      clientCombinationKey: 'SIMPLE_DEFAULT',
      productVariantId: null,
      sku: sku.isEmpty ? null : sku,
      barcode: barcode.isEmpty ? null : barcode,
      barcodeType: type,
      isAssigned: sku.isNotEmpty || barcode.isNotEmpty,
    );
    state = state.copyWith(
      step5State: state.step5State.copyWith(
        assignments: [assignment],
        parentBarcodeType: type,
        clearParentBarcodeType: type == null,
      ),
      isDirty: true,
    );
  }

  void updateBarcodeSkuAssignment(BarcodeSkuAssignmentDto updatedAssignment) {
    final type = resolveBarcodeType(
      barcode: updatedAssignment.barcode,
      existingType: updatedAssignment.barcodeType,
    );
    final resolved = updatedAssignment.copyWith(
      barcodeType: type,
      clearBarcodeType: type == null,
    );
    final list =
        List<BarcodeSkuAssignmentDto>.from(state.step5State.assignments);
    final idx = list.indexWhere((e) =>
        e.clientCombinationKey == resolved.clientCombinationKey);

    if (idx >= 0) {
      list[idx] = resolved;
    } else {
      list.add(resolved);
    }

    state = state.copyWith(
      step5State: state.step5State.copyWith(assignments: list),
      isDirty: true,
    );
  }

  /// Assigns a barcode/SKU entry into wizard state only (no product DB write).
  Future<bool> assignBarcodeSkuAndSave(
      BarcodeSkuAssignmentDto newAssignment) async {
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
      step5State:
          state.step5State.copyWith(clearDuplicateBarcodeConflict: true),
    );
  }
}
