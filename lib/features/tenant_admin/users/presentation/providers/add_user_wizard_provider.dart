import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tenant_user.dart';
import '../utils/user_api_errors.dart';
import 'tenant_user_providers.dart';

enum AddUserWizardStep { basicInformation, accessSetup, securityReview }

enum AddUserAccountStatus { inactive, invited }

enum AddUserOutletAccessMode { allOutlets, specificOutlets }

class AddUserWizardState {
  const AddUserWizardState({
    this.currentStep = AddUserWizardStep.basicInformation,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.roleId,
    this.employeeId = '',
    this.accountStatus = AddUserAccountStatus.inactive,
    this.profileMediaAssetId,
    this.profileFileName,
    this.outletAccessMode = AddUserOutletAccessMode.allOutlets,
    this.selectedOutletIds = const {},
    this.permissionOverrideEnabled = false,
    this.selectedPermissionIds = const {},
    this.isDirty = false,
    this.isSubmitting = false,
    this.fieldErrors = const {},
    this.generalError,
    this.idempotencyKey,
  });

  final AddUserWizardStep currentStep;
  final String fullName;
  final String email;
  final String phone;
  final String? roleId;
  final String employeeId;
  final AddUserAccountStatus accountStatus;
  final String? profileMediaAssetId;
  final String? profileFileName;
  final AddUserOutletAccessMode outletAccessMode;
  final Set<String> selectedOutletIds;
  final bool permissionOverrideEnabled;
  final Set<String> selectedPermissionIds;
  final bool isDirty;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final String? generalError;
  final String? idempotencyKey;

  bool get isStepOneValid =>
      fullName.trim().isNotEmpty &&
      _isValidEmail(email.trim()) &&
      roleId != null &&
      roleId!.trim().isNotEmpty;

  bool get isStepTwoValid =>
      outletAccessMode == AddUserOutletAccessMode.allOutlets ||
      selectedOutletIds.isNotEmpty;

  String get accountStatusApiValue =>
      accountStatus == AddUserAccountStatus.invited ? 'INVITED' : 'INACTIVE';

  List<String> get canonicalOutletIds =>
      outletAccessMode == AddUserOutletAccessMode.allOutlets
          ? const []
          : selectedOutletIds.toList(growable: false);

  List<String> get canonicalPermissionIds => permissionOverrideEnabled
      ? selectedPermissionIds.toList(growable: false)
      : const [];

  AddUserWizardState copyWith({
    AddUserWizardStep? currentStep,
    String? fullName,
    String? email,
    String? phone,
    String? roleId,
    String? employeeId,
    AddUserAccountStatus? accountStatus,
    String? profileMediaAssetId,
    String? profileFileName,
    AddUserOutletAccessMode? outletAccessMode,
    Set<String>? selectedOutletIds,
    bool? permissionOverrideEnabled,
    Set<String>? selectedPermissionIds,
    bool? isDirty,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? generalError,
    String? idempotencyKey,
    bool clearRole = false,
    bool clearProfileMedia = false,
    bool clearErrors = false,
    bool clearIdempotencyKey = false,
  }) {
    return AddUserWizardState(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleId: clearRole ? null : roleId ?? this.roleId,
      employeeId: employeeId ?? this.employeeId,
      accountStatus: accountStatus ?? this.accountStatus,
      profileMediaAssetId:
          clearProfileMedia ? null : profileMediaAssetId ?? this.profileMediaAssetId,
      profileFileName: clearProfileMedia ? null : profileFileName ?? this.profileFileName,
      outletAccessMode: outletAccessMode ?? this.outletAccessMode,
      selectedOutletIds: selectedOutletIds ?? this.selectedOutletIds,
      permissionOverrideEnabled:
          permissionOverrideEnabled ?? this.permissionOverrideEnabled,
      selectedPermissionIds: selectedPermissionIds ?? this.selectedPermissionIds,
      isDirty: isDirty ?? this.isDirty,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      fieldErrors: clearErrors ? const {} : fieldErrors ?? this.fieldErrors,
      generalError: clearErrors ? null : generalError ?? this.generalError,
      idempotencyKey:
          clearIdempotencyKey ? null : idempotencyKey ?? this.idempotencyKey,
    );
  }

  UserFormData toFormData() {
    return UserFormData(
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      employeeId: employeeId.trim().isEmpty ? null : employeeId.trim(),
      roleId: roleId!,
      outletIds: canonicalOutletIds,
      permissionOverrideEnabled: permissionOverrideEnabled,
      overriddenPermissionIds: canonicalPermissionIds,
      status: accountStatusApiValue,
      profileMediaAssetId: profileMediaAssetId,
    );
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }
}

final addUserWizardControllerProvider = StateNotifierProvider.autoDispose<
    AddUserWizardController, AddUserWizardState>((ref) {
  return AddUserWizardController(ref);
});

class AddUserWizardController extends StateNotifier<AddUserWizardState> {
  AddUserWizardController(this._ref) : super(const AddUserWizardState());

  final Ref _ref;

  void setFullName(String value) => _markDirty(
        state.copyWith(fullName: value, clearErrors: true),
      );

  void setEmail(String value) => _markDirty(
        state.copyWith(email: value, clearErrors: true),
      );

  void setPhone(String value) => _markDirty(
        state.copyWith(phone: value, clearErrors: true),
      );

  void setRoleId(String? value) => _markDirty(
        state.copyWith(roleId: value, clearRole: value == null, clearErrors: true),
      );

  void setEmployeeId(String value) => _markDirty(
        state.copyWith(employeeId: value, clearErrors: true),
      );

  void setAccountStatus(AddUserAccountStatus value) => _markDirty(
        state.copyWith(accountStatus: value, clearErrors: true),
      );

  void setProfileMedia({String? mediaAssetId, String? fileName}) => _markDirty(
        state.copyWith(
          profileMediaAssetId: mediaAssetId,
          profileFileName: fileName,
          clearProfileMedia: mediaAssetId == null,
          clearErrors: true,
        ),
      );

  void setOutletAccessMode(AddUserOutletAccessMode value) => _markDirty(
        state.copyWith(
          outletAccessMode: value,
          selectedOutletIds: value == AddUserOutletAccessMode.allOutlets
              ? const {}
              : state.selectedOutletIds,
          clearErrors: true,
        ),
      );

  void toggleOutlet(String outletId, bool selected) {
    final next = {...state.selectedOutletIds};
    selected ? next.add(outletId) : next.remove(outletId);
    _markDirty(state.copyWith(selectedOutletIds: next, clearErrors: true));
  }

  void setPermissionOverrideEnabled(bool value) => _markDirty(
        state.copyWith(
          permissionOverrideEnabled: value,
          selectedPermissionIds: value ? state.selectedPermissionIds : const {},
          clearErrors: true,
        ),
      );

  void togglePermission(String permissionId, bool selected) {
    final next = {...state.selectedPermissionIds};
    selected ? next.add(permissionId) : next.remove(permissionId);
    _markDirty(state.copyWith(selectedPermissionIds: next, clearErrors: true));
  }

  bool next() {
    final errors = _validateCurrentStep();
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    final nextStep = switch (state.currentStep) {
      AddUserWizardStep.basicInformation => AddUserWizardStep.accessSetup,
      AddUserWizardStep.accessSetup => AddUserWizardStep.securityReview,
      AddUserWizardStep.securityReview => AddUserWizardStep.securityReview,
    };
    state = state.copyWith(currentStep: nextStep, clearErrors: true);
    return true;
  }

  void back() {
    final previousStep = switch (state.currentStep) {
      AddUserWizardStep.basicInformation => AddUserWizardStep.basicInformation,
      AddUserWizardStep.accessSetup => AddUserWizardStep.basicInformation,
      AddUserWizardStep.securityReview => AddUserWizardStep.accessSetup,
    };
    state = state.copyWith(currentStep: previousStep, clearErrors: true);
  }

  Future<TenantUserDetail?> submit() async {
    final stepOneErrors = _validateStepOne();
    if (stepOneErrors.isNotEmpty) {
      state = state.copyWith(
        currentStep: AddUserWizardStep.basicInformation,
        fieldErrors: stepOneErrors,
      );
      return null;
    }

    final stepTwoErrors = _validateStepTwo();
    if (stepTwoErrors.isNotEmpty) {
      state = state.copyWith(
        currentStep: AddUserWizardStep.accessSetup,
        fieldErrors: stepTwoErrors,
      );
      return null;
    }

    final key = state.idempotencyKey ?? _newIdempotencyKey();
    state = state.copyWith(
      isSubmitting: true,
      idempotencyKey: key,
      clearErrors: true,
    );

    try {
      final user = await _ref.read(createUserProvider).call(
            state.toFormData(),
            idempotencyKey: key,
          );
      reset();
      return user;
    } on DioException catch (error) {
      final fieldErrors = userValidationErrors(error);
      state = state.copyWith(
        currentStep: _stepForErrors(fieldErrors),
        isSubmitting: false,
        fieldErrors: fieldErrors,
        generalError: userSubmitErrorMessage(error),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        currentStep: AddUserWizardStep.securityReview,
        isSubmitting: false,
        generalError: 'Failed to create user. Please try again.',
      );
      return null;
    }
  }

  void reset() {
    state = const AddUserWizardState();
  }

  Map<String, String> _validateCurrentStep() {
    return switch (state.currentStep) {
      AddUserWizardStep.basicInformation => _validateStepOne(),
      AddUserWizardStep.accessSetup => _validateStepTwo(),
      AddUserWizardStep.securityReview => const {},
    };
  }

  Map<String, String> _validateStepOne() {
    final errors = <String, String>{};
    if (state.fullName.trim().isEmpty) {
      errors['fullName'] = 'Full Name is required.';
    }
    if (state.email.trim().isEmpty) {
      errors['email'] = 'Email is required.';
    } else if (!AddUserWizardState._isValidEmail(state.email.trim())) {
      errors['email'] = 'Enter a valid email address.';
    }
    if (state.roleId == null || state.roleId!.trim().isEmpty) {
      errors['roleId'] = 'Role is required.';
    }
    return errors;
  }

  Map<String, String> _validateStepTwo() {
    if (state.outletAccessMode == AddUserOutletAccessMode.specificOutlets &&
        state.selectedOutletIds.isEmpty) {
      return {'outletIds': 'Select at least one outlet.'};
    }
    return const {};
  }

  AddUserWizardStep _stepForErrors(Map<String, String> errors) {
    if (errors.keys.any(_isStepOneField)) {
      return AddUserWizardStep.basicInformation;
    }
    if (errors.keys.any(_isStepTwoField)) {
      return AddUserWizardStep.accessSetup;
    }
    return AddUserWizardStep.securityReview;
  }

  bool _isStepOneField(String field) {
    return const {
      'fullName',
      'email',
      'phone',
      'phoneNumber',
      'employeeId',
      'accountStatus',
      'status',
      'roleId',
      'profileMediaAssetId',
      'profileImageMediaAssetId',
    }.contains(field);
  }

  bool _isStepTwoField(String field) {
    return field == 'outletIds' ||
        field == 'permissions' ||
        field == 'overriddenPermissionIds' ||
        field == 'permissionOverrideEnabled';
  }

  void _markDirty(AddUserWizardState next) {
    state = next.copyWith(isDirty: true);
  }

  String _newIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return 'tenant-user-${base64UrlEncode(bytes).replaceAll('=', '')}';
  }
}
