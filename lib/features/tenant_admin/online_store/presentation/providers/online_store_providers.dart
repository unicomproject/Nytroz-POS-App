import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/network/dio_error_message.dart';
import '../../data/datasources/online_store_remote_datasource.dart';
import '../../data/repositories/online_store_repository_impl.dart';
import '../../domain/entities/online_store.dart';
import '../../domain/repositories/online_store_repository.dart';

final onlineStoreRemoteDatasourceProvider =
    Provider<OnlineStoreRemoteDatasource>((ref) {
  return OnlineStoreRemoteDatasource(ref.watch(appDioProvider));
});

final onlineStoreRepositoryProvider = Provider<OnlineStoreRepository>((ref) {
  return OnlineStoreRepositoryImpl(
    ref.watch(onlineStoreRemoteDatasourceProvider),
  );
});

final onlineStoreOverviewProvider =
    FutureProvider.autoDispose<OnlineStoreOverview>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getOverview();
});

final onlineStoreReadinessProvider =
    FutureProvider.autoDispose<OnlineStoreReadiness>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getReadiness();
});

final onlineStoreActivationProvider =
    FutureProvider.autoDispose<OnlineStoreActivation>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getActivation();
});

final onlineStoreIdentityProvider =
    FutureProvider.autoDispose<OnlineStoreIdentity>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getIdentity();
});

final onlineStoreCheckoutRulesProvider =
    FutureProvider.autoDispose<OnlineStoreCheckoutRules>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getCheckoutRules();
});

final onlineStoreIdentityEditorProvider = StateNotifierProvider.autoDispose<
    OnlineStoreIdentityEditorController, OnlineStoreIdentityEditorState>((ref) {
  return OnlineStoreIdentityEditorController(ref);
});

class OnlineStoreIdentityEditorState {
  const OnlineStoreIdentityEditorState({
    this.initialized = false,
    this.storeName = '',
    this.businessDisplayName = '',
    this.storeDescription = '',
    this.storeEmail = '',
    this.storePhone = '',
    this.supportTagline = '',
    this.isDirty = false,
    this.isSaving = false,
    this.errorMessage,
    this.storeNameError,
    this.businessDisplayNameError,
    this.storeEmailError,
  });

  final bool initialized;
  final String storeName;
  final String businessDisplayName;
  final String storeDescription;
  final String storeEmail;
  final String storePhone;
  final String supportTagline;
  final bool isDirty;
  final bool isSaving;
  final String? errorMessage;
  final String? storeNameError;
  final String? businessDisplayNameError;
  final String? storeEmailError;

  bool get hasValidationErrors =>
      storeNameError != null ||
      businessDisplayNameError != null ||
      storeEmailError != null;

  OnlineStoreIdentityEditorState copyWith({
    bool? initialized,
    String? storeName,
    String? businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
    bool? isDirty,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? storeNameError,
    bool clearStoreNameError = false,
    String? businessDisplayNameError,
    bool clearBusinessDisplayNameError = false,
    String? storeEmailError,
    bool clearStoreEmailError = false,
  }) {
    return OnlineStoreIdentityEditorState(
      initialized: initialized ?? this.initialized,
      storeName: storeName ?? this.storeName,
      businessDisplayName: businessDisplayName ?? this.businessDisplayName,
      storeDescription: storeDescription ?? this.storeDescription,
      storeEmail: storeEmail ?? this.storeEmail,
      storePhone: storePhone ?? this.storePhone,
      supportTagline: supportTagline ?? this.supportTagline,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      storeNameError:
          clearStoreNameError ? null : storeNameError ?? this.storeNameError,
      businessDisplayNameError: clearBusinessDisplayNameError
          ? null
          : businessDisplayNameError ?? this.businessDisplayNameError,
      storeEmailError:
          clearStoreEmailError ? null : storeEmailError ?? this.storeEmailError,
    );
  }
}

class OnlineStoreIdentityEditorController
    extends StateNotifier<OnlineStoreIdentityEditorState> {
  OnlineStoreIdentityEditorController(this._ref)
      : super(const OnlineStoreIdentityEditorState());

  final Ref _ref;
  Future<bool>? _saveInFlight;

  void initialize(OnlineStoreIdentity identity) {
    if (state.initialized) return;
    _applyIdentity(identity);
  }

  void updateStoreName(String value) => _update(
        storeName: value,
        clearStoreNameError: true,
      );

  void updateBusinessDisplayName(String value) => _update(
        businessDisplayName: value,
        clearBusinessDisplayNameError: true,
      );

  void updateStoreDescription(String value) => _update(storeDescription: value);

  void updateStoreEmail(String value) => _update(
        storeEmail: value,
        clearStoreEmailError: true,
      );

  void updateSupportTagline(String value) => _update(supportTagline: value);

  Future<bool> saveIfNeeded() {
    final inFlight = _saveInFlight;
    if (inFlight != null) return inFlight;
    if (!state.isDirty) return Future<bool>.value(true);

    final operation = _save();
    _saveInFlight = operation;
    return operation.whenComplete(() => _saveInFlight = null);
  }

  Future<bool> _save() async {
    if (!_validate()) return false;

    state = state.copyWith(
      isSaving: true,
      clearErrorMessage: true,
    );
    try {
      final saved =
          await _ref.read(onlineStoreRepositoryProvider).updateIdentity(
                storeName: state.storeName.trim(),
                businessDisplayName: state.businessDisplayName.trim(),
                storeDescription: _optional(state.storeDescription),
                storeEmail: _optional(state.storeEmail),
                storePhone: _optional(state.storePhone),
                supportTagline: _optional(state.supportTagline),
              );
      _applyIdentity(saved);
      _ref.invalidate(onlineStoreIdentityProvider);
      _ref.invalidate(onlineStoreOverviewProvider);
      _ref.invalidate(onlineStoreReadinessProvider);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Store identity could not be saved. Please try again.',
      );
      return false;
    }
  }

  bool _validate() {
    final storeNameError = state.storeName.trim().isEmpty
        ? 'Online Store Name is required.'
        : null;
    final displayNameError = state.businessDisplayName.trim().isEmpty
        ? 'Business Display Name is required.'
        : null;
    final email = state.storeEmail.trim();
    final emailError = email.isNotEmpty &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? 'Enter a valid email address.'
        : null;

    state = state.copyWith(
      storeNameError: storeNameError,
      clearStoreNameError: storeNameError == null,
      businessDisplayNameError: displayNameError,
      clearBusinessDisplayNameError: displayNameError == null,
      storeEmailError: emailError,
      clearStoreEmailError: emailError == null,
      clearErrorMessage: true,
    );
    return !state.hasValidationErrors;
  }

  void _applyIdentity(OnlineStoreIdentity identity) {
    state = OnlineStoreIdentityEditorState(
      initialized: true,
      storeName: identity.storeName,
      businessDisplayName: identity.businessDisplayName,
      storeDescription: identity.storeDescription ?? '',
      storeEmail: identity.storeEmail ?? '',
      storePhone: identity.storePhone ?? '',
      supportTagline: identity.supportTagline ?? '',
    );
  }

  void _update({
    String? storeName,
    String? businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? supportTagline,
    bool clearStoreNameError = false,
    bool clearBusinessDisplayNameError = false,
    bool clearStoreEmailError = false,
  }) {
    state = state.copyWith(
      storeName: storeName,
      businessDisplayName: businessDisplayName,
      storeDescription: storeDescription,
      storeEmail: storeEmail,
      supportTagline: supportTagline,
      isDirty: true,
      clearErrorMessage: true,
      clearStoreNameError: clearStoreNameError,
      clearBusinessDisplayNameError: clearBusinessDisplayNameError,
      clearStoreEmailError: clearStoreEmailError,
    );
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

final onlineStoreUrlDomainProvider =
    FutureProvider.autoDispose<OnlineStoreUrlDomain>((ref) async {
  final repository = ref.watch(onlineStoreRepositoryProvider);
  final results = await Future.wait<Object>([
    repository.getUrlDomain(),
    repository.listDomains(),
  ]);
  final summary = results[0] as OnlineStoreUrlDomain;
  return OnlineStoreUrlDomain(
    storeSlug: summary.storeSlug,
    hostedUrl: summary.hostedUrl,
    domains: results[1] as List<OnlineStoreDomain>,
  );
});

final onlineStoreDomainEditorProvider = StateNotifierProvider.autoDispose<
    OnlineStoreDomainEditorController, OnlineStoreDomainEditorState>((ref) {
  return OnlineStoreDomainEditorController(ref);
});

class OnlineStoreDomainEditorState {
  const OnlineStoreDomainEditorState({
    this.initialized = false,
    this.storeSlug = '',
    this.initialStoreSlug = '',
    this.isSaving = false,
    this.errorMessage,
    this.slugError,
    this.selectedDomainId,
    this.activeOperation,
    this.activeDomainId,
    this.verificationTokens = const {},
  });

  final bool initialized;
  final String storeSlug;
  final String initialStoreSlug;
  final bool isSaving;
  final String? errorMessage;
  final String? slugError;
  final String? selectedDomainId;
  final String? activeOperation;
  final String? activeDomainId;
  final Map<String, String> verificationTokens;

  bool get isDirty => storeSlug != initialStoreSlug;
  bool get isWorking => isSaving || activeOperation != null;

  OnlineStoreDomainEditorState copyWith({
    bool? initialized,
    String? storeSlug,
    String? initialStoreSlug,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? slugError,
    bool clearSlugError = false,
    String? selectedDomainId,
    String? activeOperation,
    bool clearActiveOperation = false,
    String? activeDomainId,
    bool clearActiveDomainId = false,
    Map<String, String>? verificationTokens,
  }) {
    return OnlineStoreDomainEditorState(
      initialized: initialized ?? this.initialized,
      storeSlug: storeSlug ?? this.storeSlug,
      initialStoreSlug: initialStoreSlug ?? this.initialStoreSlug,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      slugError: clearSlugError ? null : slugError ?? this.slugError,
      selectedDomainId: selectedDomainId ?? this.selectedDomainId,
      activeOperation:
          clearActiveOperation ? null : activeOperation ?? this.activeOperation,
      activeDomainId:
          clearActiveDomainId ? null : activeDomainId ?? this.activeDomainId,
      verificationTokens: verificationTokens ?? this.verificationTokens,
    );
  }
}

class OnlineStoreDomainEditorController
    extends StateNotifier<OnlineStoreDomainEditorState> {
  OnlineStoreDomainEditorController(this._ref)
      : super(const OnlineStoreDomainEditorState());

  final Ref _ref;
  Future<bool>? _saveInFlight;

  OnlineStoreRepository get _repository =>
      _ref.read(onlineStoreRepositoryProvider);

  void initialize(OnlineStoreUrlDomain data) {
    if (state.initialized) return;
    final customDomains =
        data.domains.where((domain) => domain.domainType == 'CUSTOM');
    final selected =
        customDomains.where((domain) => domain.isPrimary).firstOrNull ??
            customDomains.firstOrNull;
    state = OnlineStoreDomainEditorState(
      initialized: true,
      storeSlug: data.storeSlug ?? '',
      initialStoreSlug: data.storeSlug ?? '',
      selectedDomainId: selected?.id,
    );
  }

  void updateStoreSlug(String value) {
    state = state.copyWith(
      storeSlug: value,
      clearError: true,
      clearSlugError: true,
    );
  }

  void selectDomain(String domainId) {
    state = state.copyWith(selectedDomainId: domainId, clearError: true);
  }

  Future<bool> saveIfNeeded() {
    final inFlight = _saveInFlight;
    if (inFlight != null) return inFlight;
    if (!state.isDirty) return Future<bool>.value(true);
    final operation = _save();
    _saveInFlight = operation;
    return operation.whenComplete(() => _saveInFlight = null);
  }

  Future<bool> _save() async {
    final validationError = _validateSlug(state.storeSlug);
    if (validationError != null) {
      state = state.copyWith(slugError: validationError, clearError: true);
      return false;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repository.updateUrl(state.storeSlug.trim());
      state = state.copyWith(
        storeSlug: saved.storeSlug ?? '',
        initialStoreSlug: saved.storeSlug ?? '',
        isSaving: false,
        clearSlugError: true,
      );
      _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            _onlineStoreErrorMessage(error, 'Store URL could not be saved.'),
        slugError: _fieldError(error, 'storeSlug'),
      );
      return false;
    }
  }

  Future<bool> createDomain(String domainName) async {
    return _domainAction('add', null, () async {
      final token = await _repository.createDomain(
        domainName: domainName,
        domainType: 'CUSTOM',
        isPrimary: false,
      );
      _rememberToken(token);
      state = state.copyWith(selectedDomainId: token.domainId);
    });
  }

  Future<bool> rotateToken(String domainId) async {
    return _domainAction('rotate', domainId, () async {
      _rememberToken(await _repository.rotateDomainToken(domainId));
    });
  }

  Future<bool> verify(String domainId) => _domainAction(
        'verify',
        domainId,
        () async {
          await _repository.verifyDomain(
            domainId,
            state.verificationTokens[domainId] ?? '',
          );
        },
      );

  Future<bool> refreshStatus(String domainId) => _domainAction(
        'refresh',
        domainId,
        () async {
          await _repository.refreshDomainStatus(domainId);
        },
      );

  Future<bool> provisionSsl(String domainId) => _domainAction(
        'ssl',
        domainId,
        () async {
          await _repository.provisionDomainSsl(domainId);
        },
      );

  Future<bool> setPrimary(String domainId) => _domainAction(
        'primary',
        domainId,
        () async {
          await _repository.setPrimaryDomain(domainId);
        },
      );

  Future<bool> deleteDomain(String domainId) => _domainAction(
        'delete',
        domainId,
        () async {
          await _repository.deleteDomain(domainId);
          final tokens = Map<String, String>.from(state.verificationTokens)
            ..remove(domainId);
          state = state.copyWith(verificationTokens: tokens);
        },
      );

  Future<bool> _domainAction(
    String operation,
    String? domainId,
    Future<void> Function() action,
  ) async {
    if (state.isWorking) return false;
    state = state.copyWith(
      activeOperation: operation,
      activeDomainId: domainId,
      clearError: true,
    );
    try {
      await action();
      state = state.copyWith(
        clearActiveOperation: true,
        clearActiveDomainId: true,
      );
      _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _onlineStoreErrorMessage(error, 'Domain action failed.'),
        clearActiveOperation: true,
        clearActiveDomainId: true,
      );
      return false;
    }
  }

  void _rememberToken(OnlineStoreDomainToken token) {
    state = state.copyWith(
      verificationTokens: {
        ...state.verificationTokens,
        token.domainId: token.verificationToken,
      },
    );
  }

  void _refresh() {
    _ref.invalidate(onlineStoreUrlDomainProvider);
    _ref.invalidate(onlineStoreOverviewProvider);
    _ref.invalidate(onlineStoreReadinessProvider);
  }

  String? _validateSlug(String value) {
    final slug = value.trim();
    if (slug.length < 3 || slug.length > 63) {
      return 'Use between 3 and 63 characters.';
    }
    if (slug.startsWith('-') ||
        slug.endsWith('-') ||
        !RegExp(r'^[A-Za-z0-9-]+$').hasMatch(slug)) {
      return 'Use only letters, numbers, and hyphens.';
    }
    const reserved = {
      'admin',
      'api',
      'app',
      'auth',
      'cdn',
      'checkout',
      'help',
      'mail',
      'oneverz',
      'pos',
      'shop',
      'static',
      'store',
      'support',
      'www',
    };
    if (reserved.contains(slug.toLowerCase())) {
      return 'This store slug is reserved.';
    }
    return null;
  }
}

String _onlineStoreErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    return messageFromDioException(error, fallback: fallback);
  }
  return fallback;
}

String? _fieldError(Object error, String field) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  final errors = data['errors'];
  if (errors is List) {
    for (final item in errors.whereType<Map>()) {
      if (item['field'] == field && item['message'] is String) {
        return item['message'] as String;
      }
    }
  }
  return null;
}

final onlineStoreBrandingProvider =
    FutureProvider.autoDispose<OnlineStoreBranding>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getBranding();
});

final onlineStoreBrandingEditorProvider = StateNotifierProvider.autoDispose<
    OnlineStoreBrandingEditorController, OnlineStoreBrandingEditorState>((ref) {
  return OnlineStoreBrandingEditorController(ref);
});

class OnlineStoreBrandingEditorState {
  const OnlineStoreBrandingEditorState({
    this.initialized = false,
    this.logoMediaAssetId,
    this.logoImageUrl,
    this.faviconMediaAssetId,
    this.faviconImageUrl,
    this.primaryColor = '',
    this.secondaryColor = '',
    this.initialLogoMediaAssetId,
    this.initialFaviconMediaAssetId,
    this.initialPrimaryColor = '',
    this.initialSecondaryColor = '',
    this.pendingLogoBytes,
    this.pendingFaviconBytes,
    this.isSaving = false,
    this.activeMediaPurpose,
    this.uploadProgress,
    this.errorMessage,
    this.primaryColorError,
    this.secondaryColorError,
  });

  final bool initialized;
  final String? logoMediaAssetId;
  final String? logoImageUrl;
  final String? faviconMediaAssetId;
  final String? faviconImageUrl;
  final String primaryColor;
  final String secondaryColor;
  final String? initialLogoMediaAssetId;
  final String? initialFaviconMediaAssetId;
  final String initialPrimaryColor;
  final String initialSecondaryColor;
  final Uint8List? pendingLogoBytes;
  final Uint8List? pendingFaviconBytes;
  final bool isSaving;
  final String? activeMediaPurpose;
  final double? uploadProgress;
  final String? errorMessage;
  final String? primaryColorError;
  final String? secondaryColorError;

  bool get isDirty =>
      logoMediaAssetId != initialLogoMediaAssetId ||
      faviconMediaAssetId != initialFaviconMediaAssetId ||
      primaryColor != initialPrimaryColor ||
      secondaryColor != initialSecondaryColor;
  bool get isWorking => isSaving || activeMediaPurpose != null;

  OnlineStoreBrandingEditorState copyWith({
    bool? initialized,
    String? logoMediaAssetId,
    bool clearLogoMediaAssetId = false,
    String? logoImageUrl,
    bool clearLogoImageUrl = false,
    String? faviconMediaAssetId,
    bool clearFaviconMediaAssetId = false,
    String? faviconImageUrl,
    bool clearFaviconImageUrl = false,
    String? primaryColor,
    String? secondaryColor,
    String? initialLogoMediaAssetId,
    bool clearInitialLogoMediaAssetId = false,
    String? initialFaviconMediaAssetId,
    bool clearInitialFaviconMediaAssetId = false,
    String? initialPrimaryColor,
    String? initialSecondaryColor,
    Uint8List? pendingLogoBytes,
    bool clearPendingLogoBytes = false,
    Uint8List? pendingFaviconBytes,
    bool clearPendingFaviconBytes = false,
    bool? isSaving,
    String? activeMediaPurpose,
    bool clearActiveMediaPurpose = false,
    double? uploadProgress,
    bool clearUploadProgress = false,
    String? errorMessage,
    bool clearError = false,
    String? primaryColorError,
    bool clearPrimaryColorError = false,
    String? secondaryColorError,
    bool clearSecondaryColorError = false,
  }) {
    return OnlineStoreBrandingEditorState(
      initialized: initialized ?? this.initialized,
      logoMediaAssetId: clearLogoMediaAssetId
          ? null
          : logoMediaAssetId ?? this.logoMediaAssetId,
      logoImageUrl:
          clearLogoImageUrl ? null : logoImageUrl ?? this.logoImageUrl,
      faviconMediaAssetId: clearFaviconMediaAssetId
          ? null
          : faviconMediaAssetId ?? this.faviconMediaAssetId,
      faviconImageUrl:
          clearFaviconImageUrl ? null : faviconImageUrl ?? this.faviconImageUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      initialLogoMediaAssetId: clearInitialLogoMediaAssetId
          ? null
          : initialLogoMediaAssetId ?? this.initialLogoMediaAssetId,
      initialFaviconMediaAssetId: clearInitialFaviconMediaAssetId
          ? null
          : initialFaviconMediaAssetId ?? this.initialFaviconMediaAssetId,
      initialPrimaryColor: initialPrimaryColor ?? this.initialPrimaryColor,
      initialSecondaryColor:
          initialSecondaryColor ?? this.initialSecondaryColor,
      pendingLogoBytes: clearPendingLogoBytes
          ? null
          : pendingLogoBytes ?? this.pendingLogoBytes,
      pendingFaviconBytes: clearPendingFaviconBytes
          ? null
          : pendingFaviconBytes ?? this.pendingFaviconBytes,
      isSaving: isSaving ?? this.isSaving,
      activeMediaPurpose: clearActiveMediaPurpose
          ? null
          : activeMediaPurpose ?? this.activeMediaPurpose,
      uploadProgress:
          clearUploadProgress ? null : uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      primaryColorError: clearPrimaryColorError
          ? null
          : primaryColorError ?? this.primaryColorError,
      secondaryColorError: clearSecondaryColorError
          ? null
          : secondaryColorError ?? this.secondaryColorError,
    );
  }
}

class OnlineStoreBrandingEditorController
    extends StateNotifier<OnlineStoreBrandingEditorState> {
  OnlineStoreBrandingEditorController(this._ref)
      : super(const OnlineStoreBrandingEditorState());

  static const logoPurpose = 'ONLINE_STORE_LOGO';
  static const faviconPurpose = 'ONLINE_STORE_FAVICON';
  static const maxMediaBytes = 5 * 1024 * 1024;
  static const supportedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/svg+xml',
    'image/x-icon',
  };

  final Ref _ref;
  Future<bool>? _saveInFlight;

  OnlineStoreRepository get _repository =>
      _ref.read(onlineStoreRepositoryProvider);

  void initialize(OnlineStoreBranding branding) {
    if (state.initialized) return;
    _applyBranding(branding);
  }

  void updatePrimaryColor(String value) {
    state = state.copyWith(
      primaryColor: value,
      clearPrimaryColorError: true,
      clearError: true,
    );
  }

  void updateSecondaryColor(String value) {
    state = state.copyWith(
      secondaryColor: value,
      clearSecondaryColorError: true,
      clearError: true,
    );
  }

  Future<bool> saveIfNeeded() {
    final inFlight = _saveInFlight;
    if (inFlight != null) return inFlight;
    if (!state.isDirty) return Future<bool>.value(true);
    final operation = _save();
    _saveInFlight = operation;
    return operation.whenComplete(() => _saveInFlight = null);
  }

  Future<bool> _save() async {
    if (!_validateColors()) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _persist(
        logoMediaAssetId: state.logoMediaAssetId,
        faviconMediaAssetId: state.faviconMediaAssetId,
      );
      _applyBranding(saved);
      _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            _onlineStoreErrorMessage(error, 'Branding could not be saved.'),
      );
      return false;
    }
  }

  Future<bool> uploadAndAttach({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (state.isWorking) return false;
    if (purpose != logoPurpose && purpose != faviconPurpose) {
      state = state.copyWith(errorMessage: 'Unsupported branding image type.');
      return false;
    }
    final validationError = _validateMedia(bytes, mimeType);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }
    final isLogo = purpose == logoPurpose;
    final previousId =
        isLogo ? state.logoMediaAssetId : state.faviconMediaAssetId;
    state = state.copyWith(
      activeMediaPurpose: purpose,
      uploadProgress: 0,
      pendingLogoBytes: isLogo ? bytes : null,
      pendingFaviconBytes: isLogo ? null : bytes,
      clearPendingLogoBytes: !isLogo,
      clearPendingFaviconBytes: isLogo,
      clearError: true,
    );
    OnlineStoreMedia? uploaded;
    try {
      uploaded = await _repository.uploadMedia(
        purpose: purpose,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );
      final saved = await _persist(
        logoMediaAssetId:
            isLogo ? uploaded.mediaAssetId : state.logoMediaAssetId,
        faviconMediaAssetId:
            isLogo ? state.faviconMediaAssetId : uploaded.mediaAssetId,
      );
      _applyBranding(saved);
      if (previousId != null && previousId != uploaded.mediaAssetId) {
        try {
          await _repository.deleteMedia(previousId);
        } catch (_) {}
      }
      _refresh();
      return true;
    } catch (error) {
      if (uploaded != null) {
        try {
          await _repository.deleteMedia(uploaded.mediaAssetId);
        } catch (_) {}
      }
      state = state.copyWith(
        errorMessage: _onlineStoreErrorMessage(error, 'Image upload failed.'),
        clearActiveMediaPurpose: true,
        clearUploadProgress: true,
        clearPendingLogoBytes: true,
        clearPendingFaviconBytes: true,
      );
      return false;
    }
  }

  Future<bool> removeAsset(String purpose) async {
    if (state.isWorking) return false;
    final isLogo = purpose == logoPurpose;
    final mediaId = isLogo ? state.logoMediaAssetId : state.faviconMediaAssetId;
    if (mediaId == null) return true;
    state = state.copyWith(activeMediaPurpose: purpose, clearError: true);
    try {
      final detached = await _persist(
        logoMediaAssetId: isLogo ? null : state.logoMediaAssetId,
        faviconMediaAssetId: isLogo ? state.faviconMediaAssetId : null,
      );
      try {
        await _repository.deleteMedia(mediaId);
      } catch (error) {
        final restored = await _persist(
          logoMediaAssetId: isLogo ? mediaId : state.logoMediaAssetId,
          faviconMediaAssetId: isLogo ? state.faviconMediaAssetId : mediaId,
        );
        _applyBranding(restored);
        state = state.copyWith(
          errorMessage:
              _onlineStoreErrorMessage(error, 'Image removal failed.'),
        );
        _refresh();
        return false;
      }
      _applyBranding(detached);
      _refresh();
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _onlineStoreErrorMessage(error, 'Image removal failed.'),
        clearActiveMediaPurpose: true,
      );
      return false;
    }
  }

  Future<OnlineStoreBranding> _persist({
    required String? logoMediaAssetId,
    required String? faviconMediaAssetId,
  }) {
    return _repository.updateBranding(
      logoMediaAssetId: logoMediaAssetId,
      faviconMediaAssetId: faviconMediaAssetId,
      primaryColor: state.primaryColor.trim(),
      secondaryColor: state.secondaryColor.trim(),
    );
  }

  bool _validateColors() {
    final primaryError = _colorError(state.primaryColor);
    final secondaryError = _colorError(state.secondaryColor);
    state = state.copyWith(
      primaryColorError: primaryError,
      clearPrimaryColorError: primaryError == null,
      secondaryColorError: secondaryError,
      clearSecondaryColorError: secondaryError == null,
      clearError: true,
    );
    return primaryError == null && secondaryError == null;
  }

  String? _colorError(String value) =>
      RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value.trim())
          ? null
          : 'Use #RRGGBB format.';

  String? _validateMedia(Uint8List bytes, String mimeType) {
    if (bytes.isEmpty || bytes.length > maxMediaBytes) {
      return 'Image must be between 1 byte and 5 MB.';
    }
    if (!supportedMimeTypes.contains(mimeType.toLowerCase())) {
      return 'Use JPEG, PNG, WebP, SVG, or ICO.';
    }
    return null;
  }

  void _applyBranding(OnlineStoreBranding branding) {
    state = OnlineStoreBrandingEditorState(
      initialized: true,
      logoMediaAssetId: branding.logoMediaAssetId,
      logoImageUrl: branding.logoImageUrl,
      faviconMediaAssetId: branding.faviconMediaAssetId,
      faviconImageUrl: branding.faviconImageUrl,
      primaryColor: branding.primaryColor,
      secondaryColor: branding.secondaryColor,
      initialLogoMediaAssetId: branding.logoMediaAssetId,
      initialFaviconMediaAssetId: branding.faviconMediaAssetId,
      initialPrimaryColor: branding.primaryColor,
      initialSecondaryColor: branding.secondaryColor,
    );
  }

  void _refresh() {
    _ref.invalidate(onlineStoreBrandingProvider);
    _ref.invalidate(onlineStoreOverviewProvider);
    _ref.invalidate(onlineStoreReadinessProvider);
  }
}

final onlineStoreBannerMutationProvider = StateNotifierProvider.autoDispose<
    OnlineStoreBannerMutationController, OnlineStoreBannerMutationState>((ref) {
  return OnlineStoreBannerMutationController(ref);
});

class OnlineStoreBannerMutationState {
  const OnlineStoreBannerMutationState({
    this.creating = false,
    this.updatingBannerId,
    this.changingStatusBannerId,
    this.deletingBannerId,
    this.reordering = false,
    this.errorMessage,
  });

  final bool creating;
  final String? updatingBannerId;
  final String? changingStatusBannerId;
  final String? deletingBannerId;
  final bool reordering;
  final String? errorMessage;

  bool get isWorking =>
      creating ||
      updatingBannerId != null ||
      changingStatusBannerId != null ||
      deletingBannerId != null ||
      reordering;

  OnlineStoreBannerMutationState copyWith({
    bool? creating,
    String? updatingBannerId,
    bool clearUpdatingBannerId = false,
    String? changingStatusBannerId,
    bool clearChangingStatusBannerId = false,
    String? deletingBannerId,
    bool clearDeletingBannerId = false,
    bool? reordering,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnlineStoreBannerMutationState(
      creating: creating ?? this.creating,
      updatingBannerId: clearUpdatingBannerId
          ? null
          : updatingBannerId ?? this.updatingBannerId,
      changingStatusBannerId: clearChangingStatusBannerId
          ? null
          : changingStatusBannerId ?? this.changingStatusBannerId,
      deletingBannerId: clearDeletingBannerId
          ? null
          : deletingBannerId ?? this.deletingBannerId,
      reordering: reordering ?? this.reordering,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class OnlineStoreBannerMutationController
    extends StateNotifier<OnlineStoreBannerMutationState> {
  OnlineStoreBannerMutationController(this._ref)
      : super(const OnlineStoreBannerMutationState());

  static const bannerMediaPurpose = 'STOREFRONT_BANNER';

  final Ref _ref;

  OnlineStoreRepository get _repository =>
      _ref.read(onlineStoreRepositoryProvider);

  Future<bool> saveBanner({
    OnlineStoreBanner? existing,
    required String bannerType,
    required String title,
    String? subtitle,
    String? actionText,
    String? actionUrl,
    required int sortOrder,
    required String status,
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageMimeType,
  }) async {
    if (state.isWorking) return false;
    state = state.copyWith(
      creating: existing == null,
      updatingBannerId: existing?.id,
      clearUpdatingBannerId: existing == null,
      clearError: true,
    );
    OnlineStoreMedia? uploaded;
    try {
      var imageMediaAssetId = existing?.imageMediaAssetId;
      if (imageBytes != null &&
          imageFileName != null &&
          imageMimeType != null) {
        uploaded = await _repository.uploadMedia(
          purpose: bannerMediaPurpose,
          bytes: imageBytes,
          fileName: imageFileName,
          mimeType: imageMimeType,
        );
        imageMediaAssetId = uploaded.mediaAssetId;
      }
      await _repository.saveBanner(
        id: existing?.id,
        data: {
          'bannerType': bannerType,
          'title': title.trim(),
          'subtitle': _nullableTrimmed(subtitle),
          'imageMediaAssetId': imageMediaAssetId,
          'actionText': _nullableTrimmed(actionText),
          'actionUrl': _nullableTrimmed(actionUrl),
          'sortOrder': sortOrder,
          'status': status,
        },
      );
      if (uploaded != null &&
          existing?.imageMediaAssetId != null &&
          existing!.imageMediaAssetId != uploaded.mediaAssetId) {
        try {
          await _repository.deleteMedia(existing.imageMediaAssetId!);
        } catch (_) {}
      }
      _refresh();
      state = const OnlineStoreBannerMutationState();
      return true;
    } catch (error) {
      if (uploaded != null) {
        try {
          await _repository.deleteMedia(uploaded.mediaAssetId);
        } catch (_) {}
      }
      state = OnlineStoreBannerMutationState(
        errorMessage: _onlineStoreErrorMessage(
          error,
          existing == null
              ? 'Banner could not be created.'
              : 'Banner could not be updated.',
        ),
      );
      return false;
    }
  }

  Future<bool> changeStatus(OnlineStoreBanner banner, String status) async {
    if (state.isWorking) return false;
    state = state.copyWith(
      changingStatusBannerId: banner.id,
      clearError: true,
    );
    try {
      await _repository.updateBannerStatus(banner.id, status);
      _refresh();
      state = const OnlineStoreBannerMutationState();
      return true;
    } catch (error) {
      state = OnlineStoreBannerMutationState(
        errorMessage: _onlineStoreErrorMessage(
          error,
          'Banner status could not be updated.',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteBanner(OnlineStoreBanner banner) async {
    if (state.isWorking) return false;
    state = state.copyWith(deletingBannerId: banner.id, clearError: true);
    try {
      await _repository.deleteBanner(banner.id);
      _refresh();
      state = const OnlineStoreBannerMutationState();
      return true;
    } catch (error) {
      state = OnlineStoreBannerMutationState(
        errorMessage: _onlineStoreErrorMessage(
          error,
          'Banner could not be deleted.',
        ),
      );
      return false;
    }
  }

  Future<bool> reorder(List<OnlineStoreBanner> banners) async {
    if (state.isWorking) return false;
    state = state.copyWith(reordering: true, clearError: true);
    try {
      await _repository.reorderBanners([
        for (var index = 0; index < banners.length; index++)
          {
            'bannerId': banners[index].id,
            'sortOrder': index,
          },
      ]);
      _refresh();
      state = const OnlineStoreBannerMutationState();
      return true;
    } catch (error) {
      state = OnlineStoreBannerMutationState(
        errorMessage: _onlineStoreErrorMessage(
          error,
          'Banner order could not be saved.',
        ),
      );
      return false;
    }
  }

  void _refresh() {
    _ref.invalidate(onlineStoreBrandingProvider);
    _ref.invalidate(onlineStoreOverviewProvider);
    _ref.invalidate(onlineStoreReadinessProvider);
  }

  String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final onlineStoreSupportProvider =
    FutureProvider.autoDispose<OnlineStoreSupport>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getSupport();
});

final onlineStoreSupportEditorProvider = StateNotifierProvider.autoDispose<
    OnlineStoreSupportEditorController, OnlineStoreSupportEditorState>((ref) {
  return OnlineStoreSupportEditorController(ref);
});

class OnlineStoreSupportEditorState {
  const OnlineStoreSupportEditorState({
    this.initialized = false,
    this.email = '',
    this.phone = '',
    this.whatsapp = '',
    this.helpUrl = '',
    this.contactUsEnabled = true,
    this.supportHours = '',
    this.businessAddress = '',
    this.initialEmail = '',
    this.initialPhone = '',
    this.initialWhatsapp = '',
    this.initialHelpUrl = '',
    this.initialContactUsEnabled = true,
    this.initialSupportHours = '',
    this.initialBusinessAddress = '',
    this.isSaving = false,
    this.errorMessage,
    this.emailError,
    this.phoneError,
    this.whatsappError,
    this.helpUrlError,
    this.supportHoursError,
    this.businessAddressError,
  });

  final bool initialized;
  final String email;
  final String phone;
  final String whatsapp;
  final String helpUrl;
  final bool contactUsEnabled;
  final String supportHours;
  final String businessAddress;
  final String initialEmail;
  final String initialPhone;
  final String initialWhatsapp;
  final String initialHelpUrl;
  final bool initialContactUsEnabled;
  final String initialSupportHours;
  final String initialBusinessAddress;
  final bool isSaving;
  final String? errorMessage;
  final String? emailError;
  final String? phoneError;
  final String? whatsappError;
  final String? helpUrlError;
  final String? supportHoursError;
  final String? businessAddressError;

  bool get isDirty =>
      email != initialEmail ||
      phone != initialPhone ||
      whatsapp != initialWhatsapp ||
      helpUrl != initialHelpUrl ||
      contactUsEnabled != initialContactUsEnabled ||
      supportHours != initialSupportHours ||
      businessAddress != initialBusinessAddress;

  bool get hasValidationErrors =>
      emailError != null ||
      phoneError != null ||
      whatsappError != null ||
      helpUrlError != null ||
      supportHoursError != null ||
      businessAddressError != null;

  OnlineStoreSupportEditorState copyWith({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    bool? contactUsEnabled,
    String? supportHours,
    String? businessAddress,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? emailError,
    bool clearEmailError = false,
    String? phoneError,
    bool clearPhoneError = false,
    String? whatsappError,
    bool clearWhatsappError = false,
    String? helpUrlError,
    bool clearHelpUrlError = false,
    String? supportHoursError,
    bool clearSupportHoursError = false,
    String? businessAddressError,
    bool clearBusinessAddressError = false,
  }) {
    return OnlineStoreSupportEditorState(
      initialized: initialized,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      helpUrl: helpUrl ?? this.helpUrl,
      contactUsEnabled: contactUsEnabled ?? this.contactUsEnabled,
      supportHours: supportHours ?? this.supportHours,
      businessAddress: businessAddress ?? this.businessAddress,
      initialEmail: initialEmail,
      initialPhone: initialPhone,
      initialWhatsapp: initialWhatsapp,
      initialHelpUrl: initialHelpUrl,
      initialContactUsEnabled: initialContactUsEnabled,
      initialSupportHours: initialSupportHours,
      initialBusinessAddress: initialBusinessAddress,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      emailError: clearEmailError ? null : emailError ?? this.emailError,
      phoneError: clearPhoneError ? null : phoneError ?? this.phoneError,
      whatsappError:
          clearWhatsappError ? null : whatsappError ?? this.whatsappError,
      helpUrlError:
          clearHelpUrlError ? null : helpUrlError ?? this.helpUrlError,
      supportHoursError: clearSupportHoursError
          ? null
          : supportHoursError ?? this.supportHoursError,
      businessAddressError: clearBusinessAddressError
          ? null
          : businessAddressError ?? this.businessAddressError,
    );
  }
}

class OnlineStoreSupportEditorController
    extends StateNotifier<OnlineStoreSupportEditorState> {
  OnlineStoreSupportEditorController(this._ref)
      : super(const OnlineStoreSupportEditorState());

  final Ref _ref;
  Future<bool>? _saveInFlight;

  void initialize(OnlineStoreSupport support) {
    if (state.initialized) return;
    _applySupport(support);
  }

  void updateEmail(String value) => state = state.copyWith(
        email: value,
        clearEmailError: true,
        clearError: true,
      );
  void updatePhone(String value) => state = state.copyWith(
        phone: value,
        clearPhoneError: true,
        clearError: true,
      );
  void updateWhatsapp(String value) => state = state.copyWith(
        whatsapp: value,
        clearWhatsappError: true,
        clearError: true,
      );
  void updateHelpUrl(String value) => state = state.copyWith(
        helpUrl: value,
        clearHelpUrlError: true,
        clearError: true,
      );
  void updateContactUsEnabled(bool value) => state = state.copyWith(
        contactUsEnabled: value,
        clearError: true,
      );
  void updateSupportHours(String value) => state = state.copyWith(
        supportHours: value,
        clearSupportHoursError: true,
        clearError: true,
      );
  void updateBusinessAddress(String value) => state = state.copyWith(
        businessAddress: value,
        clearBusinessAddressError: true,
        clearError: true,
      );

  Future<bool> saveIfNeeded() {
    final inFlight = _saveInFlight;
    if (inFlight != null) return inFlight;
    if (!state.isDirty) return Future<bool>.value(true);
    final operation = _save();
    _saveInFlight = operation;
    return operation.whenComplete(() => _saveInFlight = null);
  }

  Future<bool> _save() async {
    if (!_validate()) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved =
          await _ref.read(onlineStoreRepositoryProvider).updateSupport(
                email: _optional(state.email),
                phone: _optional(state.phone),
                whatsapp: _optional(state.whatsapp),
                helpUrl: _optional(state.helpUrl),
                contactUsEnabled: state.contactUsEnabled,
                supportHours: _optional(state.supportHours),
                businessAddress: _optional(state.businessAddress),
              );
      _applySupport(saved);
      _ref.invalidate(onlineStoreSupportProvider);
      _ref.invalidate(onlineStoreOverviewProvider);
      _ref.invalidate(onlineStoreReadinessProvider);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _onlineStoreErrorMessage(
          error,
          'Contact and support settings could not be saved.',
        ),
        emailError: _fieldError(error, 'email'),
        phoneError: _fieldError(error, 'phone'),
        whatsappError: _fieldError(error, 'whatsapp'),
        helpUrlError: _fieldError(error, 'helpUrl'),
        supportHoursError: _fieldError(error, 'supportHours'),
        businessAddressError: _fieldError(error, 'businessAddress'),
      );
      return false;
    }
  }

  bool _validate() {
    final email = state.email.trim();
    final phoneDigits = state.phone.replaceAll(RegExp(r'\D'), '');
    final helpUri = Uri.tryParse(state.helpUrl.trim());
    final emailError = email.isEmpty ||
            email.length > 320 ||
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? 'Enter a valid support email address.'
        : null;
    final phoneError = phoneDigits.length < 7 || phoneDigits.length > 15
        ? 'Enter a valid support phone number.'
        : null;
    final whatsappError = state.whatsapp.trim().length > 40
        ? 'WhatsApp number must not exceed 40 characters.'
        : null;
    final helpUrl = state.helpUrl.trim();
    final helpUrlError = helpUrl.isNotEmpty &&
            (helpUri == null ||
                helpUri.scheme.toLowerCase() != 'https' ||
                helpUri.host.isEmpty)
        ? 'Help URL must use HTTPS.'
        : null;
    final supportHoursError = _validSupportHours(state.supportHours)
        ? null
        : 'Use support hours such as Mon - Fri: 9:00 AM - 6:00 PM.';
    final address = state.businessAddress.trim();
    final businessAddressError = address.isEmpty || address.length > 1000
        ? 'Business address is required and must not exceed 1000 characters.'
        : null;
    state = state.copyWith(
      emailError: emailError,
      clearEmailError: emailError == null,
      phoneError: phoneError,
      clearPhoneError: phoneError == null,
      whatsappError: whatsappError,
      clearWhatsappError: whatsappError == null,
      helpUrlError: helpUrlError,
      clearHelpUrlError: helpUrlError == null,
      supportHoursError: supportHoursError,
      clearSupportHoursError: supportHoursError == null,
      businessAddressError: businessAddressError,
      clearBusinessAddressError: businessAddressError == null,
      clearError: true,
    );
    return !state.hasValidationErrors;
  }

  bool _validSupportHours(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return false;
    final intervalPattern = RegExp(
      r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)(?:\s*-\s*(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun))?\s*:\s*(.+?)\s*-\s*(.+)$',
      caseSensitive: false,
    );
    final intervals = trimmed
        .split(';')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    if (intervals.isEmpty) return false;
    for (final interval in intervals) {
      final match = intervalPattern.firstMatch(interval);
      if (match == null) return false;
      final open = _timeMinutes(match.group(1)!);
      final close = _timeMinutes(match.group(2)!);
      if (open == null || close == null || open >= close) return false;
    }
    return true;
  }

  int? _timeMinutes(String value) {
    final match = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0');
    final period = match.group(3)?.toUpperCase();
    if (hour == null || minute == null || minute > 59) return null;
    if (period == null) {
      if (hour > 23) return null;
    } else {
      if (hour < 1 || hour > 12) return null;
      if (hour == 12) hour = 0;
      if (period == 'PM') hour += 12;
    }
    return hour * 60 + minute;
  }

  void _applySupport(OnlineStoreSupport support) {
    final email = support.email ?? '';
    final phone = support.phone ?? '';
    final whatsapp = support.whatsapp ?? '';
    final helpUrl = support.helpUrl ?? '';
    final supportHours = support.supportHours ?? '';
    final businessAddress = support.businessAddress ?? '';
    state = OnlineStoreSupportEditorState(
      initialized: true,
      email: email,
      phone: phone,
      whatsapp: whatsapp,
      helpUrl: helpUrl,
      contactUsEnabled: support.contactUsEnabled,
      supportHours: supportHours,
      businessAddress: businessAddress,
      initialEmail: email,
      initialPhone: phone,
      initialWhatsapp: whatsapp,
      initialHelpUrl: helpUrl,
      initialContactUsEnabled: support.contactUsEnabled,
      initialSupportHours: supportHours,
      initialBusinessAddress: businessAddress,
    );
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

final onlineStoreClickCollectProvider =
    FutureProvider.autoDispose<OnlineStoreClickCollect>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getClickCollect();
});

final onlineStoreCatalogSummaryProvider =
    FutureProvider.autoDispose<OnlineStoreCatalogSummary>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getCatalogSummary();
});

final onlineStorePoliciesProvider =
    FutureProvider.autoDispose<List<OnlineStorePolicy>>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).listPolicies();
});

final onlineStoreCatalogProductsProvider =
    FutureProvider.autoDispose<OnlineStoreCatalogProductList>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).listCatalogProducts(
        pageNumber: 1,
        pageSize: 12,
      );
});

final onlineStoreProductsPoliciesProvider =
    FutureProvider.autoDispose<OnlineStoreProductsPoliciesData>((ref) async {
  final repository = ref.watch(onlineStoreRepositoryProvider);
  final results = await Future.wait<Object>([
    repository.getCatalogSummary(),
    repository.listPolicies(),
  ]);

  return OnlineStoreProductsPoliciesData(
    summary: results[0] as OnlineStoreCatalogSummary,
    policies: results[1] as List<OnlineStorePolicy>,
  );
});

class OnlineStoreProductsPoliciesData {
  const OnlineStoreProductsPoliciesData({
    required this.summary,
    required this.policies,
  });

  final OnlineStoreCatalogSummary summary;
  final List<OnlineStorePolicy> policies;
}

final onlineStoreMutationControllerProvider = StateNotifierProvider.autoDispose<
    OnlineStoreMutationController, AsyncValue<void>>((ref) {
  return OnlineStoreMutationController(ref);
});

class OnlineStoreMutationController extends StateNotifier<AsyncValue<void>> {
  OnlineStoreMutationController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  String? _publishIdempotencyKey;
  Future<void>? _publishInFlight;

  OnlineStoreRepository get _repository =>
      _ref.read(onlineStoreRepositoryProvider);

  Future<void> updateActivation(bool setupEnabled) {
    return _run(() async {
      await _repository.updateActivation(setupEnabled);
      _refreshCommon();
      _ref.invalidate(onlineStoreActivationProvider);
    });
  }

  Future<void> updateIdentity({
    required String storeName,
    required String businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
  }) {
    return _run(() async {
      await _repository.updateIdentity(
        storeName: storeName,
        businessDisplayName: businessDisplayName,
        storeDescription: storeDescription,
        storeEmail: storeEmail,
        storePhone: storePhone,
        supportTagline: supportTagline,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreIdentityProvider);
    });
  }

  Future<void> updateUrl(String storeSlug) {
    return _run(() async {
      await _repository.updateUrl(storeSlug);
      _refreshCommon();
      _ref.invalidate(onlineStoreUrlDomainProvider);
    });
  }

  Future<void> createDomain(String domainName) => _run(() async {
        await _repository.createDomain(
          domainName: domainName,
          domainType: 'CUSTOM',
          isPrimary: false,
        );
        _refreshDomain();
      });

  Future<void> verifyDomain(String domainId, String token) => _run(() async {
        await _repository.verifyDomain(domainId, token);
        _refreshDomain();
      });

  Future<void> refreshDomainStatus(String domainId) => _run(() async {
        await _repository.refreshDomainStatus(domainId);
        _refreshDomain();
      });

  Future<void> provisionDomainSsl(String domainId) => _run(() async {
        await _repository.provisionDomainSsl(domainId);
        _refreshDomain();
      });

  Future<void> setPrimaryDomain(String domainId) => _run(() async {
        await _repository.setPrimaryDomain(domainId);
        _refreshDomain();
      });

  Future<void> deleteDomain(String domainId) => _run(() async {
        await _repository.deleteDomain(domainId);
        _refreshDomain();
      });

  Future<OnlineStoreMedia?> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    OnlineStoreMedia? media;
    await _run(() async {
      media = await _repository.uploadMedia(
        purpose: purpose,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        onProgress: onProgress,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreBrandingProvider);
    });
    return media;
  }

  Future<void> deleteMedia(String mediaAssetId) {
    return _run(() async {
      await _repository.deleteMedia(mediaAssetId);
      _refreshCommon();
      _ref.invalidate(onlineStoreBrandingProvider);
    });
  }

  Future<void> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  }) {
    return _run(() async {
      await _repository.updateBranding(
        logoMediaAssetId: logoMediaAssetId,
        faviconMediaAssetId: faviconMediaAssetId,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreBrandingProvider);
    });
  }

  Future<void> updateBannerStatus(String id, String status) => _run(() async {
        await _repository.updateBannerStatus(id, status);
        _refreshBranding();
      });

  Future<void> deleteBanner(String id) => _run(() async {
        await _repository.deleteBanner(id);
        _refreshBranding();
      });

  Future<void> updateSupport({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    required bool contactUsEnabled,
    String? supportHours,
    String? businessAddress,
  }) {
    return _run(() async {
      await _repository.updateSupport(
        email: email,
        phone: phone,
        whatsapp: whatsapp,
        helpUrl: helpUrl,
        contactUsEnabled: contactUsEnabled,
        supportHours: supportHours,
        businessAddress: businessAddress,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreSupportProvider);
    });
  }

  Future<void> updateClickCollect(bool enabled) {
    return _run(() async {
      await _repository.updateClickCollect(enabled);
      _refreshCommon();
      _ref.invalidate(onlineStoreClickCollectProvider);
    });
  }

  Future<void> updateProductVisibility(String productId, bool visible) =>
      _run(() async {
        await _repository.updateProductVisibility(
          productId,
          {'isVisible': visible},
        );
        _ref.invalidate(onlineStoreCatalogProductsProvider);
        _ref.invalidate(onlineStoreProductsPoliciesProvider);
        _refreshCommon();
      });

  Future<void> publishPolicy(String type) => _run(() async {
        await _repository.publishPolicy(type);
        _ref.invalidate(onlineStorePoliciesProvider);
        _ref.invalidate(onlineStoreProductsPoliciesProvider);
        _refreshCommon();
      });

  Future<void> archivePolicy(String type) => _run(() async {
        await _repository.archivePolicy(type);
        _ref.invalidate(onlineStorePoliciesProvider);
        _ref.invalidate(onlineStoreProductsPoliciesProvider);
        _refreshCommon();
      });

  Future<void> publish() {
    final inFlight = _publishInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    _publishIdempotencyKey ??=
        'online-store-publish-${DateTime.now().microsecondsSinceEpoch}';

    final future = _run(() async {
      await _repository.publish(_publishIdempotencyKey!);
      _publishIdempotencyKey = null;
      _refreshCommon();
    }).catchError((Object error) {
      if (!_isAmbiguousPublishFailure(error)) {
        _publishIdempotencyKey = null;
      }
      throw error;
    }).whenComplete(() {
      _publishInFlight = null;
    });

    _publishInFlight = future;
    return future;
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _refreshCommon() {
    _ref.invalidate(onlineStoreOverviewProvider);
    _ref.invalidate(onlineStoreReadinessProvider);
  }

  void _refreshDomain() {
    _ref.invalidate(onlineStoreUrlDomainProvider);
    _refreshCommon();
  }

  void _refreshBranding() {
    _ref.invalidate(onlineStoreBrandingProvider);
    _refreshCommon();
  }

  bool _isAmbiguousPublishFailure(Object error) {
    if (error is! DioException) {
      return false;
    }

    if (error.response != null) {
      return false;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown =>
        true,
      _ => false,
    };
  }
}
