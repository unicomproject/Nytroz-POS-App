import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_inspection.dart';
import 'return_flow_provider.dart';
import 'return_search_provider.dart';

const returnInspectionPreValidateGuidance = InspectionPolicyMessage(
  severity: 'INFO',
  title: 'Inspection guidance',
  message:
      'Select a condition for each item. Add notes and photos when required before continuing.',
);

class ReturnInspectionState {
  const ReturnInspectionState({
    this.conditions = const [],
    this.lineInspections = const {},
    this.validationResult,
    this.isLoading = false,
    this.isSaving = false,
    this.isValidating = false,
    this.errorMessage,
    this.permissionDenied = false,
    this.inspectionsValidated = false,
    this.draftId,
    this.draftStatus,
    this.draftVersion,
    this.draftExpiresAt,
    this.showValidationMessage = false,
    this.notesMaxLength = 200,
    this.maxPhotosPerLine = 5,
    this.isRetryableServerError = false,
  });

  final List<InspectionConditionOption> conditions;
  final Map<String, ReturnLineInspection> lineInspections;
  final InspectionValidationResult? validationResult;
  final bool isLoading;
  final bool isSaving;
  final bool isValidating;
  final String? errorMessage;
  final bool permissionDenied;
  final bool inspectionsValidated;
  final String? draftId;
  final String? draftStatus;
  final int? draftVersion;
  final DateTime? draftExpiresAt;
  final bool showValidationMessage;
  final int notesMaxLength;
  final int maxPhotosPerLine;
  final bool isRetryableServerError;

  /// Prefer authoritative backend summary after a successful validate call.
  int get selectedItemCount =>
      validationResult?.selectedItemCount ??
      lineInspections.values.where((line) => line.isSelected).length;

  int get inspectedItemCount =>
      validationResult?.inspectedItemCount ??
      lineInspections.values
          .where((line) => line.isSelected && _isLineComplete(line))
          .length;

  int get pendingItemCount =>
      validationResult?.pendingItemCount ??
      (selectedItemCount - inspectedItemCount);

  bool get hasUploadInProgress => lineInspections.values.any(
        (line) => line.hasUploadInProgress,
      );

  bool get step6RequiresInspection => lineInspections.values.any((line) {
        if (!line.isSelected) {
          return false;
        }
        final condition = _conditionForLine(line);
        return condition != null &&
            (condition.requiresPhoto || condition.requiresNotes);
      });

  bool get step6RequiresManagerApproval => lineInspections.values.any((line) {
        if (!line.isSelected) {
          return false;
        }
        return _conditionForLine(line)?.requiresApproval == true;
      });

  bool get canContinue {
    if (isLoading ||
        isSaving ||
        isValidating ||
        hasUploadInProgress ||
        conditions.isEmpty) {
      return false;
    }
    if (selectedItemCount == 0) {
      return false;
    }
    return pendingItemCount == 0 && inspectedItemCount == selectedItemCount;
  }

  Map<String, int> get conditionBreakdown {
    if (validationResult != null) {
      return validationResult!.conditionBreakdown;
    }

    final breakdown = <String, int>{
      for (final condition in conditions) condition.code: 0,
      'PENDING': 0,
    };

    for (final line in lineInspections.values) {
      if (!line.isSelected) {
        continue;
      }
      final code = line.conditionCode;
      if (code == null || code.isEmpty || !_isLineComplete(line)) {
        breakdown['PENDING'] = (breakdown['PENDING'] ?? 0) + 1;
        continue;
      }
      breakdown[code] = (breakdown[code] ?? 0) + 1;
    }

    return breakdown;
  }

  List<InspectionPolicyMessage> get policyMessages =>
      validationResult?.policyMessages ?? const [];

  InspectionConditionOption? _conditionForLine(ReturnLineInspection line) {
    final code = line.conditionCode;
    if (code == null || code.isEmpty) {
      return null;
    }
    for (final option in conditions) {
      if (option.code == code) {
        return option;
      }
    }
    return null;
  }

  bool _isLineComplete(ReturnLineInspection line) {
    final condition = _conditionForLine(line);
    if (condition == null) {
      return false;
    }

    if (condition.requiresNotes && line.notes.trim().isEmpty) {
      return false;
    }

    if (condition.requiresPhoto) {
      final uploadedCount = line.media
          .where((item) =>
              item.uploadStatus == InspectionMediaUploadStatus.uploaded)
          .length;
      if (uploadedCount == 0) {
        return false;
      }
    }

    if (line.hasUploadInProgress || line.hasUploadFailure) {
      return false;
    }

    return true;
  }

  ReturnInspectionState copyWith({
    List<InspectionConditionOption>? conditions,
    Map<String, ReturnLineInspection>? lineInspections,
    InspectionValidationResult? validationResult,
    bool? isLoading,
    bool? isSaving,
    bool? isValidating,
    String? errorMessage,
    bool? permissionDenied,
    bool? inspectionsValidated,
    String? draftId,
    String? draftStatus,
    int? draftVersion,
    DateTime? draftExpiresAt,
    bool? showValidationMessage,
    int? notesMaxLength,
    int? maxPhotosPerLine,
    bool? isRetryableServerError,
    bool clearError = false,
    bool clearValidation = false,
    bool clearDraftVersion = false,
    bool clearDraftExpiresAt = false,
  }) {
    return ReturnInspectionState(
      conditions: conditions ?? this.conditions,
      lineInspections: lineInspections ?? this.lineInspections,
      validationResult:
          clearValidation ? null : validationResult ?? this.validationResult,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isValidating: isValidating ?? this.isValidating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      inspectionsValidated: clearValidation
          ? false
          : inspectionsValidated ?? this.inspectionsValidated,
      draftId: draftId ?? this.draftId,
      draftStatus: draftStatus ?? this.draftStatus,
      draftVersion:
          clearDraftVersion ? null : draftVersion ?? this.draftVersion,
      draftExpiresAt:
          clearDraftExpiresAt ? null : draftExpiresAt ?? this.draftExpiresAt,
      showValidationMessage:
          showValidationMessage ?? this.showValidationMessage,
      notesMaxLength: notesMaxLength ?? this.notesMaxLength,
      maxPhotosPerLine: maxPhotosPerLine ?? this.maxPhotosPerLine,
      isRetryableServerError:
          isRetryableServerError ?? this.isRetryableServerError,
    );
  }
}

class ReturnInspectionController extends StateNotifier<ReturnInspectionState> {
  ReturnInspectionController(this._ref) : super(const ReturnInspectionState());

  final Ref _ref;
  int _loadSequence = 0;
  int _persistSequence = 0;
  int _deleteSequence = 0;
  final Map<String, int> _uploadSequence = {};
  CancelToken? _loadCancelToken;
  CancelToken? _persistCancelToken;
  CancelToken? _deleteCancelToken;
  final Map<String, CancelToken?> _uploadCancelTokens = {};
  var _disposed = false;

  Future<void> load({
    required String saleId,
    required List<ReturnSelectedReturnLine> selectedLines,
    Map<String, ReturnLineInspection>? existingInspections,
  }) async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Device context is required to load inspection options.',
        isRetryableServerError: false,
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    _loadCancelToken?.cancel('Superseded by a newer inspection load.');
    final cancelToken = CancelToken();
    _loadCancelToken = cancelToken;
    final requestId = ++_loadSequence;

    if (!_canApplyLoad(requestId)) {
      return;
    }
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      permissionDenied: false,
      isRetryableServerError: false,
      clearValidation: true,
    );

    try {
      final conditions = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getInspectionConditions(
            deviceId: deviceContext.deviceId,
            cancelToken: cancelToken,
          );
      if (!_canApplyLoad(requestId)) {
        return;
      }

      final draft = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getInspectionDraft(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            cancelToken: cancelToken,
          );
      if (!_canApplyLoad(requestId)) {
        return;
      }

      final inspections = _buildLineInspections(
        selectedLines: selectedLines,
        existingInspections: existingInspections,
        conditions: conditions,
        draft: draft,
      );

      state = ReturnInspectionState(
        conditions: conditions,
        lineInspections: inspections,
        draftId: draft?.draftId,
        draftStatus: draft?.status,
        draftVersion: draft?.version,
        draftExpiresAt: draft?.expiresAt,
        inspectionsValidated: draft?.status == 'VALIDATED',
        isLoading: false,
      );
      _syncFlowInspections(validated: state.inspectionsValidated);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplyLoad(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        permissionDenied: error.response?.statusCode == 403,
        isRetryableServerError: _isRetryableInspectionError(error),
        errorMessage: resolveInspectionApiError(error) ??
            'Unable to load inspection conditions. Please try again.',
      );
    } catch (_) {
      if (!_canApplyLoad(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isRetryableServerError: true,
        errorMessage: 'Unable to load inspection conditions. Please try again.',
      );
    }
  }

  void selectCondition({
    required String saleLineId,
    required String conditionCode,
  }) {
    InspectionConditionOption? condition;
    for (final option in state.conditions) {
      if (option.code == conditionCode) {
        condition = option;
        break;
      }
    }
    if (condition == null) {
      return;
    }

    final current = state.lineInspections[saleLineId];
    if (current == null) {
      return;
    }

    final updated =
        Map<String, ReturnLineInspection>.from(state.lineInspections);
    updated[saleLineId] = current.copyWith(
      conditionCode: condition.code,
      conditionId: condition.id,
    );

    state = state.copyWith(
      lineInspections: updated,
      showValidationMessage: false,
      draftStatus: 'DRAFT',
      clearValidation: true,
    );
    _syncFlowInspections(validated: false);
  }

  void setNotes({
    required String saleLineId,
    required String notes,
  }) {
    final current = state.lineInspections[saleLineId];
    if (current == null) {
      return;
    }

    final trimmed = notes.length <= state.notesMaxLength
        ? notes
        : notes.substring(0, state.notesMaxLength);

    final updated =
        Map<String, ReturnLineInspection>.from(state.lineInspections);
    updated[saleLineId] = current.copyWith(notes: trimmed);

    state = state.copyWith(
      lineInspections: updated,
      draftStatus: 'DRAFT',
      clearValidation: true,
    );
    _syncFlowInspections(validated: false);
  }

  Future<void> addPhoto({
    required String saleId,
    required String saleLineId,
    required String filePath,
    required String fileName,
  }) async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    var current = state.lineInspections[saleLineId];
    if (session == null ||
        deviceContext == null ||
        current == null ||
        current.hasUploadInProgress ||
        current.media.length >= state.maxPhotosPerLine) {
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    _uploadCancelTokens[saleLineId]
        ?.cancel('Superseded by a newer inspection photo upload.');
    final cancelToken = CancelToken();
    _uploadCancelTokens[saleLineId] = cancelToken;
    final requestId = (_uploadSequence[saleLineId] ?? 0) + 1;
    _uploadSequence[saleLineId] = requestId;

    final pending = InspectionMediaItem(
      mediaId: 'pending-$saleLineId-${current.media.length}',
      previewUrl: filePath,
      localPath: filePath,
      uploadStatus: InspectionMediaUploadStatus.uploading,
    );

    var updated = Map<String, ReturnLineInspection>.from(state.lineInspections);
    updated[saleLineId] = current.copyWith(
      media: [...current.media, pending],
    );
    state = state.copyWith(
      lineInspections: updated,
      draftStatus: 'DRAFT',
      clearValidation: true,
    );

    try {
      final uploaded = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .uploadInspectionMedia(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            saleLineId: saleLineId,
            filePath: filePath,
            fileName: fileName,
            cancelToken: cancelToken,
          );

      if (!_canApplyUpload(saleLineId, requestId)) {
        return;
      }

      current = state.lineInspections[saleLineId];
      if (current == null) {
        return;
      }

      final media = [
        for (final item in current.media)
          if (item.mediaId == pending.mediaId) uploaded else item,
      ];

      updated = Map<String, ReturnLineInspection>.from(state.lineInspections);
      updated[saleLineId] = current.copyWith(media: media);
      state = state.copyWith(lineInspections: updated);
      _syncFlowInspections(validated: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) ||
          !_canApplyUpload(saleLineId, requestId)) {
        return;
      }
      _markUploadFailed(
        saleLineId: saleLineId,
        pendingMediaId: pending.mediaId,
        message: resolveInspectionApiError(error) ?? 'Photo upload failed.',
        permissionDenied: error.response?.statusCode == 403,
      );
    } catch (_) {
      if (!_canApplyUpload(saleLineId, requestId)) {
        return;
      }
      _markUploadFailed(
        saleLineId: saleLineId,
        pendingMediaId: pending.mediaId,
        message: 'Photo upload failed.',
      );
    }
  }

  Future<void> removePhoto({
    required String saleLineId,
    required String mediaId,
  }) async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    final current = state.lineInspections[saleLineId];
    if (current == null) {
      return;
    }

    if (!mediaId.startsWith('pending-') && deviceContext != null) {
      if (session == null || !session.isAuthenticated) {
        return;
      }
      _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
      _deleteCancelToken?.cancel('Superseded by a newer media delete.');
      final cancelToken = CancelToken();
      _deleteCancelToken = cancelToken;
      final requestId = ++_deleteSequence;

      try {
        await _ref
            .read(returnsRefundRemoteDatasourceProvider)
            .deleteInspectionMedia(
              deviceId: deviceContext.deviceId,
              mediaId: mediaId,
              cancelToken: cancelToken,
            );
        if (!_canApplyDelete(requestId)) {
          return;
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error) || !_canApplyDelete(requestId)) {
          return;
        }
        state = state.copyWith(
          permissionDenied: error.response?.statusCode == 403,
          isRetryableServerError: _isRetryableInspectionError(error),
          errorMessage: resolveInspectionApiError(error) ??
              'Unable to remove inspection photo. Please try again.',
        );
        return;
      } catch (_) {
        if (!_canApplyDelete(requestId)) {
          return;
        }
        state = state.copyWith(
          isRetryableServerError: true,
          errorMessage: 'Unable to remove inspection photo. Please try again.',
        );
        return;
      }
    }

    final updated =
        Map<String, ReturnLineInspection>.from(state.lineInspections);
    updated[saleLineId] = current.copyWith(
      media: current.media.where((item) => item.mediaId != mediaId).toList(),
    );
    state = state.copyWith(
      lineInspections: updated,
      draftStatus: 'DRAFT',
      clearValidation: true,
    );
    _syncFlowInspections(validated: false);
  }

  Future<bool> saveDraft({
    required String saleId,
  }) async {
    if (state.isSaving || state.isValidating) {
      return false;
    }

    return _persistDraft(
      saleId: saleId,
      forValidation: false,
    );
  }

  Future<bool> validateAndContinue({
    required String saleId,
  }) async {
    if (state.isValidating || state.isSaving) {
      return false;
    }

    if (!state.canContinue) {
      state = state.copyWith(showValidationMessage: true);
      return false;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || deviceContext == null) {
      return false;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    _persistCancelToken?.cancel('Superseded by a newer inspection validate.');
    final cancelToken = CancelToken();
    _persistCancelToken = cancelToken;
    final requestId = ++_persistSequence;

    state = state.copyWith(
      isValidating: true,
      clearError: true,
      permissionDenied: false,
      inspectionsValidated: false,
      isRetryableServerError: false,
      clearValidation: true,
    );

    if (!await _persistDraft(
      saleId: saleId,
      forValidation: true,
      cancelToken: cancelToken,
      requestId: requestId,
    )) {
      if (_canApplyPersist(requestId)) {
        state = state.copyWith(isValidating: false);
      }
      return false;
    }

    try {
      final result = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .validateInspection(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            lines: _inspectionLinesPayload(),
            reasonRefs: _reasonRefsPayload(),
            version: state.draftVersion,
            cancelToken: cancelToken,
          );

      if (!_canApplyPersist(requestId)) {
        return false;
      }

      final validated = result.isValidated;
      state = state.copyWith(
        isValidating: false,
        validationResult: result,
        notesMaxLength: result.notesMaxLength,
        maxPhotosPerLine: result.maxPhotosPerLine,
        showValidationMessage: !result.canContinue,
        draftId: result.draftId ?? state.draftId,
        draftStatus: result.status ?? state.draftStatus,
        draftVersion: result.version ?? state.draftVersion,
        draftExpiresAt: result.expiresAt ?? state.draftExpiresAt,
        inspectionsValidated: validated,
      );
      _applyValidatedFlow(validated: validated, result: result);
      return validated;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplyPersist(requestId)) {
        return false;
      }

      if (_isDraftConflict(error)) {
        await _refreshDraftAfterConflict(
          saleId: saleId,
          cancelToken: cancelToken,
          requestId: requestId,
        );
        if (!_canApplyPersist(requestId)) {
          return false;
        }
        state = state.copyWith(
          isValidating: false,
          errorMessage: resolveInspectionApiError(error) ??
              'This inspection draft was updated elsewhere. Review the refreshed draft and try again.',
        );
        return false;
      }

      state = state.copyWith(
        isValidating: false,
        permissionDenied: error.response?.statusCode == 403,
        isRetryableServerError: _isRetryableInspectionError(error),
        errorMessage: resolveInspectionApiError(error) ??
            'Unable to validate inspection. Please try again.',
      );
      return false;
    } catch (_) {
      if (!_canApplyPersist(requestId)) {
        return false;
      }
      state = state.copyWith(
        isValidating: false,
        isRetryableServerError: true,
        errorMessage: 'Unable to validate inspection. Please try again.',
      );
      return false;
    }
  }

  Future<bool> _persistDraft({
    required String saleId,
    required bool forValidation,
    CancelToken? cancelToken,
    int? requestId,
  }) async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      if (requestId == null || _canApplyPersist(requestId)) {
        state = state.copyWith(
          isSaving: false,
          errorMessage:
              'Device context is required to save the inspection draft.',
          isRetryableServerError: false,
        );
      }
      return false;
    }

    final persistRequestId = requestId ?? ++_persistSequence;
    final token = cancelToken ?? CancelToken();
    if (requestId == null) {
      _persistCancelToken?.cancel('Superseded by a newer inspection save.');
      _persistCancelToken = token;
      state = state.copyWith(
        isSaving: true,
        clearError: true,
        permissionDenied: false,
        isRetryableServerError: false,
      );
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);

    try {
      final draft = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .saveInspectionDraft(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            lines: _inspectionLinesPayload(),
            version: state.draftVersion,
            cancelToken: token,
          );

      if (!_canApplyPersist(persistRequestId)) {
        return false;
      }

      final validated = draft.status == 'VALIDATED';
      state = state.copyWith(
        isSaving: requestId == null ? false : state.isSaving,
        draftId: draft.draftId,
        draftStatus: draft.status,
        draftVersion: draft.version,
        draftExpiresAt: draft.expiresAt,
        inspectionsValidated:
            forValidation ? state.inspectionsValidated : validated,
        clearError: true,
      );
      if (!forValidation) {
        _syncFlowInspections(validated: validated);
      }
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplyPersist(persistRequestId)) {
        return false;
      }

      if (_isDraftConflict(error)) {
        await _refreshDraftAfterConflict(
          saleId: saleId,
          cancelToken: token,
          requestId: persistRequestId,
        );
        if (!_canApplyPersist(persistRequestId)) {
          return false;
        }
        state = state.copyWith(
          isSaving: requestId == null ? false : state.isSaving,
          errorMessage: resolveInspectionApiError(error) ??
              'This inspection draft was updated elsewhere. Review the refreshed draft and try again.',
        );
        return false;
      }

      state = state.copyWith(
        isSaving: requestId == null ? false : state.isSaving,
        permissionDenied: error.response?.statusCode == 403,
        isRetryableServerError: _isRetryableInspectionError(error),
        errorMessage: resolveInspectionApiError(error) ??
            'Unable to save inspection draft. Please try again.',
      );
      return false;
    } catch (_) {
      if (!_canApplyPersist(persistRequestId)) {
        return false;
      }
      state = state.copyWith(
        isSaving: requestId == null ? false : state.isSaving,
        isRetryableServerError: true,
        errorMessage: 'Unable to save inspection draft. Please try again.',
      );
      return false;
    }
  }

  Future<void> _refreshDraftAfterConflict({
    required String saleId,
    CancelToken? cancelToken,
    required int requestId,
  }) async {
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      return;
    }

    try {
      final draft = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getInspectionDraft(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            cancelToken: cancelToken,
          );
      if (!_canApplyPersist(requestId)) {
        return;
      }
      if (draft == null) {
        return;
      }

      final refreshed = _applyDraftToExistingLines(draft);
      state = state.copyWith(
        lineInspections: refreshed,
        draftId: draft.draftId,
        draftStatus: draft.status,
        draftVersion: draft.version,
        draftExpiresAt: draft.expiresAt,
        inspectionsValidated: draft.status == 'VALIDATED',
        clearValidation: true,
      );
      _syncFlowInspections(validated: draft.status == 'VALIDATED');
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplyPersist(requestId)) {
        return;
      }
      state = state.copyWith(
        errorMessage: resolveInspectionApiError(error) ??
            'Unable to refresh the inspection draft. Please reload the screen.',
        isRetryableServerError: _isRetryableInspectionError(error),
      );
    } catch (_) {
      if (!_canApplyPersist(requestId)) {
        return;
      }
      state = state.copyWith(
        errorMessage:
            'Unable to refresh the inspection draft. Please reload the screen.',
        isRetryableServerError: true,
      );
    }
  }

  Map<String, ReturnLineInspection> _applyDraftToExistingLines(
    InspectionDraft draft,
  ) {
    final updated =
        Map<String, ReturnLineInspection>.from(state.lineInspections);
    for (final entry in updated.entries) {
      InspectionDraftLine? draftLine;
      for (final item in draft.lines) {
        if (item.saleLineId == entry.key) {
          draftLine = item;
          break;
        }
      }
      if (draftLine == null) {
        continue;
      }

      InspectionConditionOption? condition;
      if (draftLine.conditionCode != null) {
        for (final option in state.conditions) {
          if (option.code == draftLine.conditionCode) {
            condition = option;
            break;
          }
        }
      }

      updated[entry.key] = entry.value.copyWith(
        conditionCode: draftLine.conditionCode,
        conditionId: condition?.id,
        notes: draftLine.notes,
        media: [
          for (final mediaId in draftLine.mediaIds)
            InspectionMediaItem(
              mediaId: mediaId,
              previewUrl: ApiEndpoints.posReturnInspectionMedia(mediaId),
            ),
        ],
      );
    }
    return updated;
  }

  Map<String, ReturnLineInspection> _buildLineInspections({
    required List<ReturnSelectedReturnLine> selectedLines,
    required List<InspectionConditionOption> conditions,
    Map<String, ReturnLineInspection>? existingInspections,
    InspectionDraft? draft,
  }) {
    final inspections = <String, ReturnLineInspection>{};
    for (final line in selectedLines) {
      final existing = existingInspections?[line.saleLineId];
      InspectionDraftLine? draftLine;
      for (final item in draft?.lines ?? const <InspectionDraftLine>[]) {
        if (item.saleLineId == line.saleLineId) {
          draftLine = item;
          break;
        }
      }
      InspectionConditionOption? condition;
      if (draftLine?.conditionCode != null) {
        for (final option in conditions) {
          if (option.code == draftLine!.conditionCode) {
            condition = option;
            break;
          }
        }
      }
      inspections[line.saleLineId] = draftLine == null
          ? existing ?? ReturnLineInspection(saleLineId: line.saleLineId)
          : ReturnLineInspection(
              saleLineId: line.saleLineId,
              conditionCode: draftLine.conditionCode,
              conditionId: condition?.id,
              notes: draftLine.notes,
              media: [
                for (final mediaId in draftLine.mediaIds)
                  InspectionMediaItem(
                    mediaId: mediaId,
                    previewUrl: ApiEndpoints.posReturnInspectionMedia(mediaId),
                  ),
              ],
            );
    }
    return inspections;
  }

  List<Map<String, dynamic>> _inspectionLinesPayload() {
    return [
      for (final entry in state.lineInspections.entries)
        if (entry.value.isSelected)
          {
            'saleLineId': entry.key,
            'conditionCode': entry.value.conditionCode,
            'notes': entry.value.notes,
            'mediaIds': [
              for (final media in entry.value.media)
                if (media.uploadStatus == InspectionMediaUploadStatus.uploaded)
                  media.mediaId,
            ],
          },
    ];
  }

  List<Map<String, dynamic>> _reasonRefsPayload() {
    final flow = _ref.read(returnFlowProvider);
    final selections = flow.lineReasonSelections;
    if (selections.isNotEmpty) {
      return [
        for (final selection in selections.values)
          if (selection.reasonCode.isNotEmpty)
            {
              'saleLineId': selection.saleLineId,
              'reasonCode': selection.reasonCode,
            },
      ];
    }

    return [
      for (final line in flow.selectedReturnLines)
        if (flow.selectedReasonCode != null &&
            flow.selectedReasonCode!.isNotEmpty)
          {
            'saleLineId': line.saleLineId,
            'reasonCode': flow.selectedReasonCode,
          },
    ];
  }

  void _markUploadFailed({
    required String saleLineId,
    required String pendingMediaId,
    required String message,
    bool permissionDenied = false,
  }) {
    final current = state.lineInspections[saleLineId];
    if (current == null) {
      return;
    }

    final media = [
      for (final item in current.media)
        if (item.mediaId == pendingMediaId)
          item.copyWith(
            uploadStatus: InspectionMediaUploadStatus.failed,
            errorMessage: message,
          )
        else
          item,
    ];

    final updated =
        Map<String, ReturnLineInspection>.from(state.lineInspections);
    updated[saleLineId] = current.copyWith(media: media);
    state = state.copyWith(
      lineInspections: updated,
      errorMessage: message,
      permissionDenied: permissionDenied,
      draftStatus: 'DRAFT',
      clearValidation: true,
    );
    _syncFlowInspections(validated: false);
  }

  void _syncFlowInspections({required bool validated}) {
    _ref.read(returnFlowProvider.notifier).setLineInspections(
          state.lineInspections,
          inspectionsValidated: validated,
        );
  }

  void _applyValidatedFlow({
    required bool validated,
    required InspectionValidationResult result,
  }) {
    _ref.read(returnFlowProvider.notifier).applyInspectionValidation(
          inspections: state.lineInspections,
          inspectionsValidated: validated,
          step6RequiresInspection: state.step6RequiresInspection,
          step6RequiresManagerApproval: state.step6RequiresManagerApproval,
          validationRequiresInspection: result.requiresInspection,
          validationRequiresManagerApproval: result.requiresManagerApproval,
        );
  }

  bool _canApplyLoad(int requestId) => !_disposed && requestId == _loadSequence;

  bool _canApplyPersist(int requestId) =>
      !_disposed && requestId == _persistSequence;

  bool _canApplyDelete(int requestId) =>
      !_disposed && requestId == _deleteSequence;

  bool _canApplyUpload(String saleLineId, int requestId) =>
      !_disposed && _uploadSequence[saleLineId] == requestId;

  @override
  void dispose() {
    _disposed = true;
    _loadSequence++;
    _persistSequence++;
    _deleteSequence++;
    for (final saleLineId in _uploadSequence.keys.toList()) {
      _uploadSequence[saleLineId] = (_uploadSequence[saleLineId] ?? 0) + 1;
    }
    _loadCancelToken?.cancel('Return inspection provider disposed.');
    _persistCancelToken?.cancel('Return inspection provider disposed.');
    _deleteCancelToken?.cancel('Return inspection provider disposed.');
    for (final token in _uploadCancelTokens.values) {
      token?.cancel('Return inspection provider disposed.');
    }
    super.dispose();
  }
}

final returnInspectionProvider = StateNotifierProvider.autoDispose<
    ReturnInspectionController, ReturnInspectionState>(
  (ref) => ReturnInspectionController(ref),
);

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

String? _readApiError(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }
  return null;
}

String? _readApiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final code = data['code'];
    if (code is String && code.trim().isNotEmpty) {
      return code.trim();
    }
  }
  return null;
}

bool _isDraftConflict(DioException error) {
  final code = _readApiErrorCode(error);
  return error.response?.statusCode == 409 ||
      code == 'pos_returns.inspection_draft_conflict' ||
      code == 'pos_returns.concurrency_conflict';
}

bool _isRetryableInspectionError(DioException error) {
  return error.response?.statusCode == 500 ||
      _readApiErrorCode(error) == 'pos_returns.inspection_validate_failed' ||
      _readApiErrorCode(error) == 'pos_returns.inspection_draft_save_failed';
}

String? resolveInspectionApiError(DioException error) {
  final code = _readApiErrorCode(error);
  final message = _readApiError(error);

  switch (code) {
    case 'pos_returns.inspection_draft_expired':
      return message ??
          'Your inspection draft has expired. Reload inspection to continue.';
    case 'pos_returns.inspection_draft_conflict':
    case 'pos_returns.concurrency_conflict':
      return message ??
          'This inspection draft was updated elsewhere. Review the refreshed draft and try again.';
    case 'pos_returns.inspection_draft_consumed':
      return message ??
          'This inspection draft was already used. Start a new return to inspect items again.';
    case 'pos_returns.inspection_draft_not_found':
    case 'pos_returns.sale_not_found':
    case 'pos_returns.media_not_found':
      return message ?? 'The requested inspection resource could not be found.';
    case 'pos_returns.inspection_media_too_large':
      return message ?? 'Photo is too large. Choose a smaller image and retry.';
    case 'pos_returns.inspection_media_invalid_type':
      return message ??
          'Photo type is not supported. Choose a JPEG or PNG image and retry.';
  }

  final status = error.response?.statusCode;
  if (status == 413) {
    return message ?? 'Photo is too large. Choose a smaller image and retry.';
  }
  if (status == 415) {
    return message ??
        'Photo type is not supported. Choose a JPEG or PNG image and retry.';
  }
  if (status == 404) {
    return message ?? 'The requested inspection resource could not be found.';
  }
  if (status == 500) {
    return message ?? 'A server error occurred. Please try again.';
  }

  return message;
}
