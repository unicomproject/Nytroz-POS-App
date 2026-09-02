import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tenant_user.dart';
import '../utils/user_api_errors.dart';
import 'tenant_user_providers.dart';

enum AddUserWizardStep {
  basicInformation,
  assignRole,
  configurePermissions,
  accessScope,
  securityReview,
}

enum AddUserAccountStatus { invited, active, inactive }

enum AddUserOutletAccessMode {
  allOutlets('ALL_OUTLETS'),
  selectedOutlets('SELECTED_OUTLETS'),
  noOutletAccess('NO_OUTLET_ACCESS');

  const AddUserOutletAccessMode(this.apiValue);
  final String apiValue;
}

enum AddUserTillAccessMode {
  allAccessibleTills('ALL_ACCESSIBLE_TILLS'),
  selectedTills('SELECTED_TILLS'),
  noTillAccess('NO_TILL_ACCESS');

  const AddUserTillAccessMode(this.apiValue);
  final String apiValue;
}

class AddUserWizardState {
  const AddUserWizardState({
    this.currentStep = AddUserWizardStep.basicInformation,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.employeeId = '',
    this.accountStatus = AddUserAccountStatus.invited,
    this.password = '',
    this.confirmPassword = '',
    this.profileMediaAssetId,
    this.profileFileName,
    this.roleId,
    this.permissionOverrideEnabled = false,
    this.selectedPermissionIds = const {},
    this.permissionCatalogVersion,
    this.selectedPermissionGroupIndex = 0,
    this.outletAccessMode = AddUserOutletAccessMode.allOutlets,
    this.selectedOutletIds = const {},
    this.defaultOutletId,
    this.tillAccessMode = AddUserTillAccessMode.allAccessibleTills,
    this.selectedTillIds = const {},
    this.defaultTillId,
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
  final String employeeId;
  final AddUserAccountStatus accountStatus;
  final String password;
  final String confirmPassword;
  final String? profileMediaAssetId;
  final String? profileFileName;
  final String? roleId;
  final bool permissionOverrideEnabled;
  final Set<String> selectedPermissionIds;
  final String? permissionCatalogVersion;
  final int selectedPermissionGroupIndex;
  final AddUserOutletAccessMode outletAccessMode;
  final Set<String> selectedOutletIds;
  final String? defaultOutletId;
  final AddUserTillAccessMode tillAccessMode;
  final Set<String> selectedTillIds;
  final String? defaultTillId;
  final bool isDirty;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final String? generalError;
  final String? idempotencyKey;

  String get accountStatusApiValue => switch (accountStatus) {
        AddUserAccountStatus.invited => 'INVITED',
        AddUserAccountStatus.active => 'ACTIVE',
        AddUserAccountStatus.inactive => 'INACTIVE',
      };

  List<String> get canonicalOutletIds =>
      outletAccessMode == AddUserOutletAccessMode.selectedOutlets
          ? (selectedOutletIds.toList(growable: false)..sort())
          : const [];

  List<String> get canonicalTillIds =>
      tillAccessMode == AddUserTillAccessMode.selectedTills
          ? (selectedTillIds.toList(growable: false)..sort())
          : const [];

  List<String> get canonicalPermissionIds => permissionOverrideEnabled
      ? (selectedPermissionIds.toList(growable: false)..sort())
      : const [];

  bool get hasBasicInformation =>
      fullName.trim().isNotEmpty && _isValidEmail(email.trim());

  bool get hasRole => roleId != null && roleId!.trim().isNotEmpty;

  AddUserWizardState copyWith({
    AddUserWizardStep? currentStep,
    String? fullName,
    String? email,
    String? phone,
    String? employeeId,
    AddUserAccountStatus? accountStatus,
    String? password,
    String? confirmPassword,
    String? profileMediaAssetId,
    String? profileFileName,
    String? roleId,
    bool? permissionOverrideEnabled,
    Set<String>? selectedPermissionIds,
    String? permissionCatalogVersion,
    int? selectedPermissionGroupIndex,
    AddUserOutletAccessMode? outletAccessMode,
    Set<String>? selectedOutletIds,
    String? defaultOutletId,
    AddUserTillAccessMode? tillAccessMode,
    Set<String>? selectedTillIds,
    String? defaultTillId,
    bool? isDirty,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? generalError,
    String? idempotencyKey,
    bool clearProfileMedia = false,
    bool clearRole = false,
    bool clearCatalogVersion = false,
    bool clearDefaultOutlet = false,
    bool clearDefaultTill = false,
    bool clearErrors = false,
    bool clearIdempotencyKey = false,
  }) {
    return AddUserWizardState(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
      accountStatus: accountStatus ?? this.accountStatus,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      profileMediaAssetId: clearProfileMedia
          ? null
          : profileMediaAssetId ?? this.profileMediaAssetId,
      profileFileName:
          clearProfileMedia ? null : profileFileName ?? this.profileFileName,
      roleId: clearRole ? null : roleId ?? this.roleId,
      permissionOverrideEnabled:
          permissionOverrideEnabled ?? this.permissionOverrideEnabled,
      selectedPermissionIds:
          selectedPermissionIds ?? this.selectedPermissionIds,
      permissionCatalogVersion: clearCatalogVersion
          ? null
          : permissionCatalogVersion ?? this.permissionCatalogVersion,
      selectedPermissionGroupIndex:
          selectedPermissionGroupIndex ?? this.selectedPermissionGroupIndex,
      outletAccessMode: outletAccessMode ?? this.outletAccessMode,
      selectedOutletIds: selectedOutletIds ?? this.selectedOutletIds,
      defaultOutletId:
          clearDefaultOutlet ? null : defaultOutletId ?? this.defaultOutletId,
      tillAccessMode: tillAccessMode ?? this.tillAccessMode,
      selectedTillIds: selectedTillIds ?? this.selectedTillIds,
      defaultTillId:
          clearDefaultTill ? null : defaultTillId ?? this.defaultTillId,
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
      email: email.trim().toLowerCase(),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      employeeId: employeeId.trim().isEmpty ? null : employeeId.trim(),
      roleId: roleId!,
      outletIds: canonicalOutletIds,
      permissionOverrideEnabled: permissionOverrideEnabled,
      overriddenPermissionIds: canonicalPermissionIds,
      sendInviteEmail: accountStatus == AddUserAccountStatus.invited,
      status: accountStatusApiValue,
      profileMediaAssetId: profileMediaAssetId,
      outletAccessScope: outletAccessMode.apiValue,
      defaultOutletId: defaultOutletId,
      tillAccessScope: tillAccessMode.apiValue,
      tillIds: canonicalTillIds,
      defaultTillId: defaultTillId,
      permissionCatalogVersion: permissionCatalogVersion,
      password: accountStatus == AddUserAccountStatus.active ? password : null,
      confirmPassword:
          accountStatus == AddUserAccountStatus.active ? confirmPassword : null,
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

  void syncCreateOptions(TenantUserCreateOptions options) {
    final supported = options.supportedStatuses
        .map((status) => status.trim().toUpperCase())
        .toSet();
    final nextStatus = supported.contains(state.accountStatusApiValue)
        ? state.accountStatus
        : supported.contains('INVITED')
            ? AddUserAccountStatus.invited
            : supported.contains('ACTIVE')
                ? AddUserAccountStatus.active
                : AddUserAccountStatus.inactive;
    state = state.copyWith(
      accountStatus: nextStatus,
      permissionCatalogVersion: options.permissionCatalogVersion,
    );
  }

  void setFullName(String value) =>
      _markDirty(state.copyWith(fullName: value, clearErrors: true));

  void setEmail(String value) =>
      _markDirty(state.copyWith(email: value, clearErrors: true));

  void setPhone(String value) =>
      _markDirty(state.copyWith(phone: value, clearErrors: true));

  void setEmployeeId(String value) =>
      _markDirty(state.copyWith(employeeId: value, clearErrors: true));

  void setAccountStatus(AddUserAccountStatus value) => _markDirty(
        state.copyWith(
          accountStatus: value,
          password: value == AddUserAccountStatus.active ? null : '',
          confirmPassword: value == AddUserAccountStatus.active ? null : '',
          clearErrors: true,
        ),
      );

  void setPassword(String value) =>
      _markDirty(state.copyWith(password: value, clearErrors: true));

  void setConfirmPassword(String value) =>
      _markDirty(state.copyWith(confirmPassword: value, clearErrors: true));

  void setProfileMedia({String? mediaAssetId, String? fileName}) => _markDirty(
        state.copyWith(
          profileMediaAssetId: mediaAssetId,
          profileFileName: fileName,
          clearProfileMedia: mediaAssetId == null,
          clearErrors: true,
        ),
      );

  void setRoleId(String? value) {
    if (state.roleId == value) return;
    _markDirty(
      state.copyWith(
        roleId: value,
        clearRole: value == null,
        permissionOverrideEnabled: false,
        selectedPermissionIds: const {},
        selectedPermissionGroupIndex: 0,
        clearErrors: true,
      ),
    );
  }

  void setPermissionGroupIndex(int value) {
    state = state.copyWith(selectedPermissionGroupIndex: value);
  }

  void setPermissionOverrideEnabled(
    bool value, {
    Iterable<String> inheritedPermissionIds = const [],
  }) =>
      _markDirty(
        state.copyWith(
          permissionOverrideEnabled: value,
          selectedPermissionIds: value
              ? (state.selectedPermissionIds.isEmpty
                  ? inheritedPermissionIds.toSet()
                  : state.selectedPermissionIds)
              : const {},
          clearErrors: true,
        ),
      );

  void togglePermission(String permissionId, bool selected) {
    final next = {...state.selectedPermissionIds};
    selected ? next.add(permissionId) : next.remove(permissionId);
    _markDirty(state.copyWith(selectedPermissionIds: next, clearErrors: true));
  }

  void setOutletAccessMode(AddUserOutletAccessMode value) {
    if (value == AddUserOutletAccessMode.noOutletAccess) {
      _markDirty(
        state.copyWith(
          outletAccessMode: value,
          selectedOutletIds: const {},
          clearDefaultOutlet: true,
          tillAccessMode: AddUserTillAccessMode.noTillAccess,
          selectedTillIds: const {},
          clearDefaultTill: true,
          clearErrors: true,
        ),
      );
      return;
    }

    _markDirty(
      state.copyWith(
        outletAccessMode: value,
        selectedOutletIds: value == AddUserOutletAccessMode.allOutlets
            ? const {}
            : state.selectedOutletIds,
        tillAccessMode:
            state.tillAccessMode == AddUserTillAccessMode.noTillAccess
                ? AddUserTillAccessMode.allAccessibleTills
                : state.tillAccessMode,
        clearErrors: true,
      ),
    );
  }

  void toggleOutlet(
    String outletId,
    bool selected, {
    required Iterable<UserTillOption> tills,
  }) {
    final outlets = {...state.selectedOutletIds};
    selected ? outlets.add(outletId) : outlets.remove(outletId);
    final allowedTillIds = tills
        .where((till) => outlets.contains(till.outletId))
        .map((till) => till.id)
        .toSet();
    final selectedTills = state.selectedTillIds.intersection(allowedTillIds);
    _markDirty(
      state.copyWith(
        selectedOutletIds: outlets,
        selectedTillIds: selectedTills,
        clearDefaultOutlet: state.defaultOutletId != null &&
            !outlets.contains(state.defaultOutletId),
        clearDefaultTill: state.defaultTillId != null &&
            !allowedTillIds.contains(state.defaultTillId),
        clearErrors: true,
      ),
    );
  }

  void setDefaultOutlet(String? value) => _markDirty(
        state.copyWith(
          defaultOutletId: value,
          clearDefaultOutlet: value == null,
          clearErrors: true,
        ),
      );

  void setTillAccessMode(AddUserTillAccessMode value) => _markDirty(
        state.copyWith(
          tillAccessMode: value,
          selectedTillIds: value == AddUserTillAccessMode.selectedTills
              ? state.selectedTillIds
              : const {},
          clearDefaultTill: value == AddUserTillAccessMode.noTillAccess,
          clearErrors: true,
        ),
      );

  void toggleTill(String tillId, bool selected) {
    final next = {...state.selectedTillIds};
    selected ? next.add(tillId) : next.remove(tillId);
    _markDirty(
      state.copyWith(
        selectedTillIds: next,
        clearDefaultTill:
            state.defaultTillId == tillId && !next.contains(tillId),
        clearErrors: true,
      ),
    );
  }

  void setDefaultTill(String? value) => _markDirty(
        state.copyWith(
          defaultTillId: value,
          clearDefaultTill: value == null,
          clearErrors: true,
        ),
      );

  bool next() {
    final errors = _validateCurrentStep();
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    final index = AddUserWizardStep.values.indexOf(state.currentStep);
    if (index < AddUserWizardStep.values.length - 1) {
      state = state.copyWith(
        currentStep: AddUserWizardStep.values[index + 1],
        clearErrors: true,
      );
    }
    return true;
  }

  void back() {
    final index = AddUserWizardStep.values.indexOf(state.currentStep);
    if (index > 0) {
      state = state.copyWith(
        currentStep: AddUserWizardStep.values[index - 1],
        clearErrors: true,
      );
    }
  }

  void goToCompletedStep(AddUserWizardStep step) {
    final target = AddUserWizardStep.values.indexOf(step);
    final current = AddUserWizardStep.values.indexOf(state.currentStep);
    if (target < current) {
      state = state.copyWith(currentStep: step, clearErrors: true);
    }
  }

  Future<TenantUserDetail?> submit() async {
    if (state.isSubmitting) return null;

    for (final step in AddUserWizardStep.values.take(4)) {
      final errors = _validateStep(step);
      if (errors.isNotEmpty) {
        state = state.copyWith(currentStep: step, fieldErrors: errors);
        return null;
      }
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
      final code = _errorCode(error);
      if (code == 'user.permission_catalog_mismatch') {
        _ref.invalidate(userCreateOptionsProvider);
      }
      state = state.copyWith(
        currentStep: _stepForErrors(fieldErrors, code),
        isSubmitting: false,
        fieldErrors: fieldErrors,
        generalError: code == 'user.permission_catalog_mismatch'
            ? 'Permissions have changed. Refresh the access catalog before continuing.'
            : userSubmitErrorMessage(error),
        clearCatalogVersion: code == 'user.permission_catalog_mismatch',
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

  Map<String, String> _validateCurrentStep() =>
      _validateStep(state.currentStep);

  Map<String, String> _validateStep(AddUserWizardStep step) {
    return switch (step) {
      AddUserWizardStep.basicInformation => _validateBasicInformation(),
      AddUserWizardStep.assignRole => _validateRole(),
      AddUserWizardStep.configurePermissions => _validatePermissions(),
      AddUserWizardStep.accessScope => _validateAccessScope(),
      AddUserWizardStep.securityReview => const {},
    };
  }

  Map<String, String> _validateBasicInformation() {
    final errors = <String, String>{};
    if (state.fullName.trim().isEmpty) {
      errors['fullName'] = 'Full Name is required.';
    }
    if (state.email.trim().isEmpty) {
      errors['email'] = 'Email is required.';
    } else if (!AddUserWizardState._isValidEmail(state.email.trim())) {
      errors['email'] = 'Enter a valid email address.';
    }
    if (state.accountStatus == AddUserAccountStatus.active) {
      if (state.password.isEmpty) {
        errors['password'] = 'Password is required for an active user.';
      } else if (state.password.length < 8) {
        errors['password'] = 'Password must be at least 8 characters.';
      } else if (!RegExp(r'[a-z]').hasMatch(state.password) ||
          !RegExp(r'[A-Z]').hasMatch(state.password) ||
          !RegExp(r'[0-9]').hasMatch(state.password)) {
        errors['password'] =
            'Use uppercase, lowercase, and at least one number.';
      }
      if (state.confirmPassword.isEmpty) {
        errors['confirmPassword'] = 'Confirm the password.';
      } else if (state.password != state.confirmPassword) {
        errors['confirmPassword'] = 'Passwords do not match.';
      }
    }
    return errors;
  }

  Map<String, String> _validateRole() {
    return state.hasRole ? const {} : {'roleId': 'Select a role to continue.'};
  }

  Map<String, String> _validatePermissions() {
    if (state.permissionOverrideEnabled &&
        (state.permissionCatalogVersion == null ||
            state.permissionCatalogVersion!.trim().isEmpty)) {
      return {'permissions': 'Refresh the permission catalog to continue.'};
    }
    return const {};
  }

  Map<String, String> _validateAccessScope() {
    final errors = <String, String>{};
    if (state.outletAccessMode == AddUserOutletAccessMode.selectedOutlets &&
        state.selectedOutletIds.isEmpty) {
      errors['outletIds'] = 'Select at least one outlet.';
    }
    if (state.outletAccessMode == AddUserOutletAccessMode.selectedOutlets &&
        state.defaultOutletId != null &&
        !state.selectedOutletIds.contains(state.defaultOutletId)) {
      errors['defaultOutletId'] =
          'Default outlet must be one of the selected outlets.';
    }
    if (state.tillAccessMode == AddUserTillAccessMode.selectedTills &&
        state.selectedTillIds.isEmpty) {
      errors['tillIds'] = 'Select at least one till.';
    }
    if (state.tillAccessMode == AddUserTillAccessMode.selectedTills &&
        state.defaultTillId != null &&
        !state.selectedTillIds.contains(state.defaultTillId)) {
      errors['defaultTillId'] =
          'Default till must be one of the selected tills.';
    }
    return errors;
  }

  AddUserWizardStep _stepForErrors(
    Map<String, String> errors,
    String? code,
  ) {
    if (code == 'user.permission_catalog_mismatch' ||
        code == 'user.invalid_permissions' ||
        code == 'user.permission_not_assignable') {
      return AddUserWizardStep.configurePermissions;
    }
    if (code == 'user.role_not_found' || code == 'user.role_not_delegable') {
      return AddUserWizardStep.assignRole;
    }
    if (errors.keys.any(_basicInformationFields.contains)) {
      return AddUserWizardStep.basicInformation;
    }
    if (errors.keys.any(_roleFields.contains)) {
      return AddUserWizardStep.assignRole;
    }
    if (errors.keys.any(_permissionFields.contains)) {
      return AddUserWizardStep.configurePermissions;
    }
    if (errors.keys.any(_accessFields.contains) ||
        code?.contains('outlet') == true ||
        code?.contains('till') == true) {
      return AddUserWizardStep.accessScope;
    }
    return AddUserWizardStep.securityReview;
  }

  void _markDirty(AddUserWizardState next) {
    state = next.copyWith(isDirty: true, clearIdempotencyKey: true);
  }

  String _newIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return 'tenant-user-${base64UrlEncode(bytes).replaceAll('=', '')}';
  }
}

const _basicInformationFields = {
  'fullName',
  'email',
  'phone',
  'phoneNumber',
  'employeeId',
  'accountStatus',
  'createStatus',
  'profileMediaAssetId',
};

const _roleFields = {'roleId'};

const _permissionFields = {
  'permissions',
  'overriddenPermissionIds',
  'permissionOverrideEnabled',
  'permissionCatalogVersion',
};

const _accessFields = {
  'outletAccessScope',
  'outletIds',
  'defaultOutletId',
  'tillAccessScope',
  'tillIds',
  'defaultTillId',
};

String? _errorCode(DioException error) {
  final data = error.response?.data;
  return data is Map ? data['code']?.toString() : null;
}
