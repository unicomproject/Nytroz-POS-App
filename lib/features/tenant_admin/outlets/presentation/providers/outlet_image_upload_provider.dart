import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/usecases/delete_staged_outlet_image.dart';
import '../../application/usecases/upload_outlet_image.dart';
import '../../domain/entities/outlet_image_upload.dart';
import 'outlet_providers.dart';

enum OutletImageUploadStatus {
  idle,
  selecting,
  uploading,
  uploaded,
  deleting,
  failed
}

class OutletImageUploadState {
  const OutletImageUploadState(
      {this.status = OutletImageUploadStatus.idle,
      this.mediaAssetId,
      this.previewBytes,
      this.remoteImageUrl,
      this.fileName,
      this.mimeType,
      this.fileSizeBytes,
      this.progress = 0,
      this.errorMessage,
      this.pendingInput});
  final OutletImageUploadStatus status;
  final String? mediaAssetId;
  final Uint8List? previewBytes;
  final String? remoteImageUrl;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final double progress;
  final String? errorMessage;
  final OutletImageUploadInput? pendingInput;

  OutletImageUploadState copyWith(
          {OutletImageUploadStatus? status,
          String? mediaAssetId,
          Uint8List? previewBytes,
          String? remoteImageUrl,
          String? fileName,
          String? mimeType,
          int? fileSizeBytes,
          double? progress,
          String? errorMessage,
          OutletImageUploadInput? pendingInput,
          bool clearError = false,
          bool clearMedia = false}) =>
      OutletImageUploadState(
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
          pendingInput: pendingInput ?? this.pendingInput);
}

abstract class OutletImagePicker {
  Future<OutletImageUploadInput?> pickImage();
}

class GalleryOutletImagePicker implements OutletImagePicker {
  GalleryOutletImagePicker(this._picker);
  final ImagePicker _picker;
  @override
  Future<OutletImageUploadInput?> pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final name = file.name;
    final extension = name.split('.').last.toLowerCase();
    final mimeType =
        file.mimeType ?? (extension == 'png' ? 'image/png' : 'image/jpeg');
    final bytes = await file.readAsBytes();
    return OutletImageUploadInput(
        bytes: bytes, fileName: name, mimeType: mimeType);
  }
}

final outletImagePickerProvider = Provider<OutletImagePicker>(
    (ref) => GalleryOutletImagePicker(ImagePicker()));
final outletImageUploadControllerProvider = StateNotifierProvider.autoDispose<
        OutletImageUploadController, OutletImageUploadState>(
    (ref) => OutletImageUploadController(
        ref.read(outletImagePickerProvider),
        ref.read(uploadOutletImageProvider),
        ref.read(deleteStagedOutletImageProvider)));

class OutletImageUploadController
    extends StateNotifier<OutletImageUploadState> {
  OutletImageUploadController(this._picker, this._upload, this._delete)
      : super(const OutletImageUploadState());
  final OutletImagePicker _picker;
  final UploadOutletImage _upload;
  final DeleteStagedOutletImage _delete;

  Future<void> chooseImage() async {
    state = state.copyWith(
        status: OutletImageUploadStatus.selecting, clearError: true);
    try {
      final input = await _picker.pickImage();
      if (input == null) {
        state = state.copyWith(
            status: state.mediaAssetId == null
                ? OutletImageUploadStatus.idle
                : OutletImageUploadStatus.uploaded);
        return;
      }
      await _uploadInput(input, replacing: false);
    } catch (_) {
      state = state.copyWith(
          status: OutletImageUploadStatus.failed,
          errorMessage: 'We could not read the selected image.');
    }
  }

  Future<void> replaceImage() async {
    final old = state;
    state = old.copyWith(
        status: OutletImageUploadStatus.selecting, clearError: true);
    try {
      final input = await _picker.pickImage();
      if (input == null) {
        state = old;
        return;
      }
      await _uploadInput(input, replacing: true, previousId: old.mediaAssetId);
    } catch (_) {
      state = old.copyWith(
          status: OutletImageUploadStatus.failed,
          errorMessage: 'We could not read the selected image.');
    }
  }

  Future<void> retryUpload() async {
    final input = state.pendingInput;
    if (input != null) await _uploadInput(input, replacing: false);
  }

  Future<void> removeImage() async {
    final id = state.mediaAssetId;
    if (id == null) {
      reset();
      return;
    }
    final old = state;
    state = old.copyWith(
        status: OutletImageUploadStatus.deleting, clearError: true);
    try {
      await _delete(id);
      reset();
    } catch (_) {
      state = old.copyWith(
          status: OutletImageUploadStatus.failed,
          errorMessage:
              'The image upload service is unavailable. Try again later.');
    }
  }

  void initializeExistingImage(
          {required String mediaAssetId,
          String? imageUrl,
          String? fileName,
          String? mimeType,
          int? fileSizeBytes}) =>
      state = OutletImageUploadState(
          status: OutletImageUploadStatus.uploaded,
          mediaAssetId: mediaAssetId,
          remoteImageUrl: imageUrl,
          fileName: fileName,
          mimeType: mimeType,
          fileSizeBytes: fileSizeBytes);
  void reset() => state = const OutletImageUploadState();
  Future<void> _uploadInput(OutletImageUploadInput input,
      {required bool replacing, String? previousId}) async {
    final extension = input.fileName.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png'}.contains(extension)) {
      state = state.copyWith(
          status: OutletImageUploadStatus.failed,
          errorMessage: 'Upload a JPG or PNG image.',
          pendingInput: input);
      return;
    }
    if (input.bytes.length > 2 * 1024 * 1024) {
      state = state.copyWith(
          status: OutletImageUploadStatus.failed,
          errorMessage: 'Upload an image smaller than 2 MB.',
          pendingInput: input);
      return;
    }
    state = state.copyWith(
        status: OutletImageUploadStatus.uploading,
        previewBytes: input.bytes,
        fileName: input.fileName,
        mimeType: input.mimeType,
        fileSizeBytes: input.bytes.length,
        progress: 0,
        pendingInput: input,
        clearError: true);
    try {
      final uploaded = await _upload(input, onProgress: (sent, total) {
        if (total > 0) state = state.copyWith(progress: sent / total);
      });
      state = state.copyWith(
          status: OutletImageUploadStatus.uploaded,
          mediaAssetId: uploaded.mediaAssetId,
          remoteImageUrl: uploaded.imageUrl,
          progress: 1,
          clearError: true);
      if (replacing &&
          previousId != null &&
          previousId != uploaded.mediaAssetId) {
        try {
          await _delete(previousId);
        } catch (_) {}
      }
    } catch (_) {
      state = state.copyWith(
          status: OutletImageUploadStatus.failed,
          errorMessage: 'We could not upload the outlet image. Try again.');
    }
  }
}
