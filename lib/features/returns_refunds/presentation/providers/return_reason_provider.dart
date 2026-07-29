import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_reason_option.dart';
import 'return_search_provider.dart';

const returnReasonNotesMaxLength = 1000;

class ReturnReasonState {
  const ReturnReasonState({
    this.reasons = const [],
    this.lineSelections = const {},
    this.selectedReasonCode,
    this.notes = '',
    this.applySameReasonToAll = true,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveErrorMessage,
    this.permissionDenied = false,
    this.reasonsValidated = false,
    this.showValidationMessage = false,
    this.isRetryableServerError = false,
  });

  final List<ReturnReasonOption> reasons;
  final Map<String, ReturnLineReasonSelection> lineSelections;
  final String? selectedReasonCode;
  final String notes;
  final bool applySameReasonToAll;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? saveErrorMessage;
  final bool permissionDenied;
  final bool reasonsValidated;
  final bool showValidationMessage;
  final bool isRetryableServerError;

  ReturnReasonOption? get selectedReason {
    final code = selectedReasonCode;
    if (code == null || code.isEmpty) {
      return null;
    }
    return _findReason(code);
  }

  bool get hasSelectedReason =>
      selectedReasonCode != null && selectedReasonCode!.isNotEmpty;

  bool get hasReasonOptions => reasons.isNotEmpty;

  bool get notesRequired => selectedReason?.requiresNotes == true;

  bool get anyRequiresInspection =>
      lineSelections.values.any((selection) => selection.requiresInspection);

  bool get anyRequiresManagerApproval => lineSelections.values
      .any((selection) => selection.requiresManagerApproval);

  String? get validationMessage {
    if (!showValidationMessage) {
      return null;
    }
    if (!hasReasonOptions) {
      return 'Return reasons are unavailable. Please retry or contact support.';
    }
    if (applySameReasonToAll) {
      if (!hasSelectedReason) {
        return 'Select a return reason to continue.';
      }
      if (notesRequired && notes.trim().isEmpty) {
        return 'Notes are required for the selected reason.';
      }
      return 'Complete all required fields to continue.';
    }

    for (final selection in lineSelections.values) {
      if (selection.reasonCode.isEmpty) {
        return 'Select a return reason for every item.';
      }
      final reason = _findReason(selection.reasonCode);
      if (reason == null) {
        return 'Select a valid return reason for every item.';
      }
      if (reason.requiresNotes && selection.notes.trim().isEmpty) {
        return 'Notes are required for one or more selected reasons.';
      }
    }
    return 'Complete all required fields to continue.';
  }

  bool get canContinue {
    if (lineSelections.isEmpty || !hasReasonOptions || isLoading || isSaving) {
      return false;
    }

    for (final selection in lineSelections.values) {
      if (selection.reasonCode.isEmpty) {
        return false;
      }
      final reason = _findReason(selection.reasonCode);
      if (reason == null) {
        return false;
      }
      if (reason.requiresNotes && selection.notes.trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  ReturnReasonOption? _findReason(String code) {
    for (final reason in reasons) {
      if (reason.code == code) {
        return reason;
      }
    }
    return null;
  }

  ReturnReasonState copyWith({
    List<ReturnReasonOption>? reasons,
    Map<String, ReturnLineReasonSelection>? lineSelections,
    String? selectedReasonCode,
    String? notes,
    bool? applySameReasonToAll,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? saveErrorMessage,
    bool? permissionDenied,
    bool? reasonsValidated,
    bool? showValidationMessage,
    bool? isRetryableServerError,
    bool clearError = false,
    bool clearSaveError = false,
    bool clearSelectedReason = false,
  }) {
    return ReturnReasonState(
      reasons: reasons ?? this.reasons,
      lineSelections: lineSelections ?? this.lineSelections,
      selectedReasonCode: clearSelectedReason
          ? null
          : selectedReasonCode ?? this.selectedReasonCode,
      notes: notes ?? this.notes,
      applySameReasonToAll: applySameReasonToAll ?? this.applySameReasonToAll,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      saveErrorMessage:
          clearSaveError ? null : saveErrorMessage ?? this.saveErrorMessage,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      reasonsValidated: reasonsValidated ?? this.reasonsValidated,
      showValidationMessage:
          showValidationMessage ?? this.showValidationMessage,
      isRetryableServerError:
          isRetryableServerError ?? this.isRetryableServerError,
    );
  }
}

class ReturnReasonController extends StateNotifier<ReturnReasonState> {
  ReturnReasonController(this._ref) : super(const ReturnReasonState());

  final Ref _ref;
  int _loadSequence = 0;
  int _saveSequence = 0;
  CancelToken? _loadCancelToken;
  CancelToken? _saveCancelToken;
  var _disposed = false;

  Future<void> load({
    required List<String> saleLineIds,
    String? selectedReasonCode,
    String notes = '',
    bool applySameReasonToAll = true,
    Map<String, ReturnLineReasonSelection>? existingSelections,
  }) async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Device context is required to load return reasons.',
        isRetryableServerError: false,
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    _loadCancelToken?.cancel('Superseded by a newer return-reasons load.');
    final cancelToken = CancelToken();
    _loadCancelToken = cancelToken;
    final requestId = ++_loadSequence;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      isRetryableServerError: false,
      permissionDenied: false,
    );

    try {
      final reasons = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getReturnReasons(
            deviceId: deviceContext.deviceId,
            cancelToken: cancelToken,
          );

      if (!_canApplyLoad(requestId)) {
        return;
      }

      final initialSelections = _buildLineSelections(
        saleLineIds: saleLineIds,
        existingSelections: existingSelections,
        selectedReasonCode: selectedReasonCode,
        notes: notes,
        applySameReasonToAll: applySameReasonToAll,
        reasons: reasons,
      );

      state = ReturnReasonState(
        reasons: reasons,
        lineSelections: initialSelections,
        selectedReasonCode: selectedReasonCode,
        notes: notes,
        applySameReasonToAll: applySameReasonToAll,
        isLoading: false,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplyLoad(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        permissionDenied: error.response?.statusCode == 403,
        isRetryableServerError: error.response?.statusCode == 500,
        errorMessage: _readApiError(error) ??
            'Unable to load return reasons. Please try again.',
      );
    } catch (_) {
      if (!_canApplyLoad(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isRetryableServerError: true,
        errorMessage: 'Unable to load return reasons. Please try again.',
      );
    }
  }

  void selectReason(String code) {
    final reason = _findReason(code);
    if (reason == null) {
      return;
    }

    final updatedSelections = Map<String, ReturnLineReasonSelection>.from(
      state.lineSelections,
    );

    if (state.applySameReasonToAll) {
      for (final saleLineId in updatedSelections.keys) {
        updatedSelections[saleLineId] = ReturnLineReasonSelection(
          saleLineId: saleLineId,
          reasonCode: code,
          reasonId: reason.id,
          notes: state.notes,
          requiresNotes: reason.requiresNotes,
          requiresInspection: reason.requiresInspection,
          requiresManagerApproval: reason.requiresManagerApproval,
        );
      }
    }

    state = state.copyWith(
      selectedReasonCode: code,
      lineSelections: updatedSelections,
      showValidationMessage: false,
      reasonsValidated: false,
      clearSaveError: true,
      isRetryableServerError: false,
    );
  }

  void selectLineReason({
    required String saleLineId,
    required String code,
  }) {
    final reason = _findReason(code);
    if (reason == null || !state.lineSelections.containsKey(saleLineId)) {
      return;
    }

    final updatedSelections = Map<String, ReturnLineReasonSelection>.from(
      state.lineSelections,
    );
    final existing = updatedSelections[saleLineId]!;
    updatedSelections[saleLineId] = existing.copyWith(
      reasonCode: code,
      reasonId: reason.id,
      requiresNotes: reason.requiresNotes,
      requiresInspection: reason.requiresInspection,
      requiresManagerApproval: reason.requiresManagerApproval,
    );

    state = state.copyWith(
      lineSelections: updatedSelections,
      showValidationMessage: false,
      reasonsValidated: false,
      clearSaveError: true,
      isRetryableServerError: false,
    );
  }

  void setNotes(String value) {
    final trimmed = value.length <= returnReasonNotesMaxLength
        ? value
        : value.substring(0, returnReasonNotesMaxLength);

    final updatedSelections = Map<String, ReturnLineReasonSelection>.from(
      state.lineSelections,
    );

    if (state.applySameReasonToAll) {
      for (final entry in updatedSelections.entries) {
        updatedSelections[entry.key] = entry.value.copyWith(notes: trimmed);
      }
    }

    state = state.copyWith(
      notes: trimmed,
      lineSelections: updatedSelections,
      reasonsValidated: false,
      clearSaveError: true,
      isRetryableServerError: false,
    );
  }

  void setLineNotes({
    required String saleLineId,
    required String value,
  }) {
    if (!state.lineSelections.containsKey(saleLineId)) {
      return;
    }

    final trimmed = value.length <= returnReasonNotesMaxLength
        ? value
        : value.substring(0, returnReasonNotesMaxLength);

    final updatedSelections = Map<String, ReturnLineReasonSelection>.from(
      state.lineSelections,
    );
    updatedSelections[saleLineId] =
        updatedSelections[saleLineId]!.copyWith(notes: trimmed);

    state = state.copyWith(
      lineSelections: updatedSelections,
      reasonsValidated: false,
      clearSaveError: true,
      isRetryableServerError: false,
    );
  }

  void setApplySameReasonToAll(bool value) {
    if (value) {
      final code = state.selectedReasonCode;
      final reason = code == null ? null : _findReason(code);
      final updatedSelections = Map<String, ReturnLineReasonSelection>.from(
        state.lineSelections,
      );
      if (reason != null) {
        for (final saleLineId in updatedSelections.keys) {
          updatedSelections[saleLineId] = ReturnLineReasonSelection(
            saleLineId: saleLineId,
            reasonCode: reason.code,
            reasonId: reason.id,
            notes: state.notes,
            requiresNotes: reason.requiresNotes,
            requiresInspection: reason.requiresInspection,
            requiresManagerApproval: reason.requiresManagerApproval,
          );
        }
      }
      state = state.copyWith(
        applySameReasonToAll: true,
        lineSelections: updatedSelections,
        reasonsValidated: false,
        clearSaveError: true,
      );
      return;
    }

    // Checked → unchecked: seed each line from the current global values.
    final updatedSelections = Map<String, ReturnLineReasonSelection>.from(
      state.lineSelections,
    );
    final globalReason = state.selectedReason;
    for (final saleLineId in updatedSelections.keys) {
      final existing = updatedSelections[saleLineId]!;
      if (existing.reasonCode.isEmpty && globalReason != null) {
        updatedSelections[saleLineId] = ReturnLineReasonSelection(
          saleLineId: saleLineId,
          reasonCode: globalReason.code,
          reasonId: globalReason.id,
          notes: state.notes,
          requiresNotes: globalReason.requiresNotes,
          requiresInspection: globalReason.requiresInspection,
          requiresManagerApproval: globalReason.requiresManagerApproval,
        );
      } else if (existing.notes.isEmpty && state.notes.isNotEmpty) {
        updatedSelections[saleLineId] = existing.copyWith(notes: state.notes);
      }
    }

    state = state.copyWith(
      applySameReasonToAll: false,
      lineSelections: updatedSelections,
      reasonsValidated: false,
      clearSaveError: true,
    );
  }

  bool validate() {
    if (state.canContinue) {
      state = state.copyWith(showValidationMessage: false);
      return true;
    }

    state = state.copyWith(showValidationMessage: true);
    return false;
  }

  /// Authoritative backend validation before advancing to Inspect Items.
  /// There is no mid-flow return-draft persistence table; this validates reason
  /// codes/notes against master data and sale lines.
  Future<bool> saveValidatedReasons({required String saleId}) async {
    if (!validate()) {
      return false;
    }

    if (state.isSaving) {
      return false;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        saveErrorMessage: 'Device context is required to save return reasons.',
        isRetryableServerError: false,
      );
      return false;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    _saveCancelToken?.cancel('Superseded by a newer return-reasons validate.');
    final cancelToken = CancelToken();
    _saveCancelToken = cancelToken;
    final requestId = ++_saveSequence;

    state = state.copyWith(
      isSaving: true,
      clearSaveError: true,
      permissionDenied: false,
      reasonsValidated: false,
      isRetryableServerError: false,
    );

    try {
      final payload = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .validateReturnReasons(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            applySameReasonToAll: state.applySameReasonToAll,
            items: [
              for (final selection in state.lineSelections.values)
                {
                  'saleLineId': selection.saleLineId,
                  'reasonCode': selection.reasonCode,
                  if (selection.notes.trim().isNotEmpty)
                    'notes': selection.notes.trim(),
                },
            ],
            cancelToken: cancelToken,
          );

      if (!_canApplySave(requestId)) {
        return false;
      }

      final items = payload['items'];
      if (items is List) {
        final updated = Map<String, ReturnLineReasonSelection>.from(
          state.lineSelections,
        );
        for (final raw in items.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final saleLineId = map['saleLineId']?.toString() ?? '';
          if (saleLineId.isEmpty || !updated.containsKey(saleLineId)) {
            continue;
          }
          final reasonCode = map['reasonCode']?.toString() ?? '';
          final catalogReason = _findReason(reasonCode);
          updated[saleLineId] = ReturnLineReasonSelection(
            saleLineId: saleLineId,
            reasonCode: reasonCode,
            reasonId: map['reasonId']?.toString(),
            notes: map['notes']?.toString() ?? '',
            requiresNotes: map['requiresNotes'] == true ||
                catalogReason?.requiresNotes == true,
            requiresInspection: map['requiresInspection'] == true ||
                catalogReason?.requiresInspection == true,
            requiresManagerApproval: map['requiresManagerApproval'] == true ||
                catalogReason?.requiresManagerApproval == true,
          );
        }
        state = state.copyWith(
          isSaving: false,
          lineSelections: updated,
          reasonsValidated: true,
        );
      } else {
        state = state.copyWith(isSaving: false, reasonsValidated: true);
      }
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplySave(requestId)) {
        return false;
      }
      state = state.copyWith(
        isSaving: false,
        permissionDenied: error.response?.statusCode == 403,
        isRetryableServerError: error.response?.statusCode == 500,
        saveErrorMessage: _readApiError(error) ??
            'Unable to save return reasons. Please try again.',
      );
      return false;
    } catch (_) {
      if (!_canApplySave(requestId)) {
        return false;
      }
      state = state.copyWith(
        isSaving: false,
        isRetryableServerError: true,
        saveErrorMessage: 'Unable to save return reasons. Please try again.',
      );
      return false;
    }
  }

  bool _canApplyLoad(int requestId) => !_disposed && requestId == _loadSequence;

  bool _canApplySave(int requestId) => !_disposed && requestId == _saveSequence;

  ReturnReasonOption? _findReason(String code) {
    for (final reason in state.reasons) {
      if (reason.code == code) {
        return reason;
      }
    }
    return null;
  }

  Map<String, ReturnLineReasonSelection> _buildLineSelections({
    required List<String> saleLineIds,
    required List<ReturnReasonOption> reasons,
    Map<String, ReturnLineReasonSelection>? existingSelections,
    String? selectedReasonCode,
    String notes = '',
    bool applySameReasonToAll = true,
  }) {
    final selections = <String, ReturnLineReasonSelection>{};
    ReturnReasonOption? selectedReason;
    if (selectedReasonCode != null) {
      for (final reason in reasons) {
        if (reason.code == selectedReasonCode) {
          selectedReason = reason;
          break;
        }
      }
    }

    for (final saleLineId in saleLineIds) {
      final existing = existingSelections?[saleLineId];
      if (existing != null && !applySameReasonToAll) {
        final reason = _lookupReason(reasons, existing.reasonCode);
        selections[saleLineId] = existing.copyWith(
          requiresNotes: reason?.requiresNotes ?? existing.requiresNotes,
          requiresInspection:
              reason?.requiresInspection ?? existing.requiresInspection,
          requiresManagerApproval: reason?.requiresManagerApproval ??
              existing.requiresManagerApproval,
        );
        continue;
      }

      final reason =
          selectedReason ?? _lookupReason(reasons, existing?.reasonCode ?? '');
      selections[saleLineId] = ReturnLineReasonSelection(
        saleLineId: saleLineId,
        reasonCode: selectedReason?.code ?? existing?.reasonCode ?? '',
        reasonId: selectedReason?.id ?? existing?.reasonId,
        notes: applySameReasonToAll ? notes : (existing?.notes ?? notes),
        requiresNotes: reason?.requiresNotes ?? false,
        requiresInspection: reason?.requiresInspection ?? false,
        requiresManagerApproval: reason?.requiresManagerApproval ?? false,
      );
    }

    return selections;
  }

  ReturnReasonOption? _lookupReason(
    List<ReturnReasonOption> reasons,
    String code,
  ) {
    if (code.isEmpty) {
      return null;
    }
    for (final reason in reasons) {
      if (reason.code == code) {
        return reason;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _loadCancelToken?.cancel('Return reason provider disposed.');
    _saveCancelToken?.cancel('Return reason provider disposed.');
    _loadSequence++;
    _saveSequence++;
    super.dispose();
  }
}

final returnReasonProvider = StateNotifierProvider.autoDispose<
    ReturnReasonController, ReturnReasonState>(
  (ref) => ReturnReasonController(ref),
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

String? validateReturnReasonCode(
  String? value,
  List<ReturnReasonOption> reasons,
) {
  if (value == null || value.isEmpty) {
    return 'A return reason is required.';
  }

  for (final reason in reasons) {
    if (reason.code == value) {
      return null;
    }
  }

  return 'Select a valid return reason.';
}
