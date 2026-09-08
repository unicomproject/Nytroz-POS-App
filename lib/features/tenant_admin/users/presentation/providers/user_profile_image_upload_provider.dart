import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/user_profile_image_upload.dart';
import '../../domain/repositories/tenant_user_repository.dart';
import 'tenant_user_providers.dart';

enum UserProfileImageUploadStatus {
  idle,
  selecting,
  uploading,
  uploaded,
  deleting,
  failed,
}

class UserProfileImageUploadState {
  const UserProfileImageUploadState({
    this.status = UserProfileImageUploadStatus.idle,
    this.mediaAssetId,
    this.previewBytes,
    this.remoteImageUrl,
    this.fileName,
    this.mimeType,
    this.fileSizeBytes,
    this.progress = 0,
    this.errorMessage,
    this.pendingInput,
    this.isPersisted = false,
    this.changeAction,
  });

  final UserProfileImageUploadStatus status;
  final String? mediaAssetId;
  final Uint8List? previewBytes;
  final String? remoteImageUrl;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final double progress;
  final String? errorMessage;
  final UserProfileImageUploadInput? pendingInput;
  final bool isPersisted;
  final String? changeAction;

  UserProfileImageUploadState copyWith({
    UserProfileImageUploadStatus? status,
    String? mediaAssetId,
    Uint8List? previewBytes,
    String? remoteImageUrl,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    double? progress,
    String? errorMessage,
    UserProfileImageUploadInput? pendingInput,
    bool? isPersisted,
    String? changeAction,
    bool clearError = false,
    bool clearMedia = false,
    bool clearPendingInput = false,
    bool clearChangeAction = false,
  }) {
    return UserProfileImageUploadState(
      status: status ?? this.status,
      mediaAssetId: clearMedia ? null : mediaAssetId ?? this.mediaAssetId,
      previewBytes: clearMedia ? null : previewBytes ?? this.previewBytes,
      remoteImageUrl:
          clearMedia ? null : remoteImageUrl ?? this.remoteImageUrl,
      fileName: clearMedia ? null : fileName ?? this.fileName,
      mimeType: clearMedia ? null : mimeType ?? this.mimeType,
      fileSizeBytes:
          clearMedia ? null : fileSizeBytes ?? this.fileSizeBytes,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      pendingInput: clearPendingInput ? null : pendingInput ?? this.pendingInput,
      isPersisted: isPersisted ?? this.isPersisted,
      changeAction:
          clearChangeAction ? null : changeAction ?? this.changeAction,
    );
  }
}

abstract class UserProfileImagePicker {
  Future<UserProfileImageUploadInput?> pickImage();
}

class GalleryUserProfileImagePicker implements UserProfileImagePicker {
  GalleryUserProfileImagePicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<UserProfileImageUploadInput?> pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final extension = file.name.split('.').last.toLowerCase();
    final mimeType = file.mimeType ??
        (extension == 'png' ? 'image/png' : 'image/jpeg');
    return UserProfileImageUploadInput(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: mimeType,
    );
  }
}

final userProfileImagePickerProvider = Provider<UserProfileImagePicker>(
  (ref) => GalleryUserProfileImagePicker(ImagePicker()),
);

final userProfileImageUploadControllerProvider = StateNotifierProvider.autoDispose<
    UserProfileImageUploadController, UserProfileImageUploadState>(
  (ref) => UserProfileImageUploadController(
    ref.read(userProfileImagePickerProvider),
    ref.read(tenantUserRepositoryProvider),
  ),
);

class UserProfileImageUploadController
    extends StateNotifier<UserProfileImageUploadState> {
  UserProfileImageUploadController(this._picker, this._repository)
      : super(const UserProfileImageUploadState());

  final UserProfileImagePicker _picker;
  final TenantUserRepository _repository;

  Future<void> chooseImage() async => _selectAndUpload();

  Future<void> replaceImage() async => _selectAndUpload(replacing: true);

  Future<void> retryUpload() async {
    final input = state.pendingInput;
    if (input != null) {
      await _uploadInput(
        input,
        fallbackState: state.isPersisted ? state : null,
      );
    }
  }

  Future<void> removeImage() async {
    final mediaAssetId = state.mediaAssetId;
    if (mediaAssetId == null) {
      state = const UserProfileImageUploadState();
      return;
    }

    if (state.isPersisted) {
      state = const UserProfileImageUploadState(changeAction: 'REMOVE');
      return;
    }

    final previous = state;
    state = state.copyWith(
      status: UserProfileImageUploadStatus.deleting,
      clearError: true,
    );
    try {
      await _repository.deleteStagedProfileImage(mediaAssetId);
      if (!mounted) return;
      state = const UserProfileImageUploadState();
    } catch (_) {
      if (!mounted) return;
      state = previous.copyWith(
        status: UserProfileImageUploadStatus.failed,
        errorMessage: 'We could not remove the profile image. Try again.',
      );
    }
  }

  void initializeExistingImage({
    required String mediaAssetId,
    String? imageUrl,
  }) {
    if (state.mediaAssetId == mediaAssetId && state.isPersisted) return;
    state = UserProfileImageUploadState(
      status: UserProfileImageUploadStatus.uploaded,
      mediaAssetId: mediaAssetId,
      remoteImageUrl: imageUrl,
      fileName: 'Current profile image',
      isPersisted: true,
    );
  }

  void reset() => state = const UserProfileImageUploadState();

  Future<void> discardStagedImage() async {
    if (state.mediaAssetId != null && !state.isPersisted) {
      try {
        await _repository.deleteStagedProfileImage(state.mediaAssetId!);
      } catch (_) {}
    }
    if (mounted) reset();
  }

  Future<void> _selectAndUpload({bool replacing = false}) async {
    final previous = state;
    state = state.copyWith(
      status: UserProfileImageUploadStatus.selecting,
      clearError: true,
    );
    try {
      final input = await _picker.pickImage();
      if (!mounted) return;
      if (input == null) {
        state = previous;
        return;
      }
      await _uploadInput(
        input,
        previousStagedMediaAssetId:
            replacing && !previous.isPersisted ? previous.mediaAssetId : null,
        fallbackState: previous.isPersisted ? previous : null,
      );
    } catch (_) {
      if (!mounted) return;
      state = previous.copyWith(
        status: UserProfileImageUploadStatus.failed,
        errorMessage: 'We could not read the selected image.',
      );
    }
  }

  Future<void> _uploadInput(
    UserProfileImageUploadInput input, {
    String? previousStagedMediaAssetId,
    UserProfileImageUploadState? fallbackState,
  }) async {
    final extension = input.fileName.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png'}.contains(extension)) {
      state = (fallbackState ?? state).copyWith(
        status: UserProfileImageUploadStatus.failed,
        errorMessage: 'Upload a JPG or PNG image.',
        pendingInput: input,
      );
      return;
    }
    if (input.bytes.length > 2 * 1024 * 1024) {
      state = (fallbackState ?? state).copyWith(
        status: UserProfileImageUploadStatus.failed,
        errorMessage: 'Upload an image smaller than 2 MB.',
        pendingInput: input,
      );
      return;
    }

    state = UserProfileImageUploadState(
      status: UserProfileImageUploadStatus.uploading,
      previewBytes: input.bytes,
      fileName: input.fileName,
      mimeType: input.mimeType,
      fileSizeBytes: input.bytes.length,
      pendingInput: input,
      changeAction: 'REPLACE',
    );
    try {
      final uploaded = await _repository.uploadProfileImage(
        input,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );
      if (!mounted) return;
      state = state.copyWith(
        status: UserProfileImageUploadStatus.uploaded,
        mediaAssetId: uploaded.mediaAssetId,
        remoteImageUrl: uploaded.imageUrl,
        progress: 1,
        isPersisted: false,
        changeAction: 'REPLACE',
        clearError: true,
      );
      if (previousStagedMediaAssetId != null &&
          previousStagedMediaAssetId != uploaded.mediaAssetId) {
        try {
          await _repository
              .deleteStagedProfileImage(previousStagedMediaAssetId);
        } catch (_) {}
      }
    } catch (_) {
      if (!mounted) return;
      state = (fallbackState ?? state).copyWith(
        status: UserProfileImageUploadStatus.failed,
        errorMessage: 'We could not upload the profile image. Try again.',
      );
    }
  }
}
