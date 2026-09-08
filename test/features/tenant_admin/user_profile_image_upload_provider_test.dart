import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/user_profile_image_upload.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/repositories/tenant_user_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/user_profile_image_upload_provider.dart';

void main() {
  test('gallery image is uploaded and exposes media asset id', () async {
    final repository = _FakeRepository();
    final controller = UserProfileImageUploadController(
      _FakePicker(_input()),
      repository,
    );
    addTearDown(controller.dispose);

    await controller.chooseImage();

    expect(controller.state.status, UserProfileImageUploadStatus.uploaded);
    expect(controller.state.mediaAssetId, 'media-1');
    expect(controller.state.previewBytes, isNotEmpty);
    expect(controller.state.changeAction, 'REPLACE');
    expect(repository.uploadCount, 1);
  });

  test('images larger than 2 MB are rejected before upload', () async {
    final repository = _FakeRepository();
    final controller = UserProfileImageUploadController(
      _FakePicker(UserProfileImageUploadInput(
        bytes: Uint8List(2 * 1024 * 1024 + 1),
        fileName: 'large.jpg',
        mimeType: 'image/jpeg',
      )),
      repository,
    );
    addTearDown(controller.dispose);

    await controller.chooseImage();

    expect(controller.state.status, UserProfileImageUploadStatus.failed);
    expect(controller.state.errorMessage, contains('smaller than 2 MB'));
    expect(repository.uploadCount, 0);
  });

  test('removing an existing image marks it for removal without staged delete',
      () async {
    final repository = _FakeRepository();
    final controller = UserProfileImageUploadController(
      _FakePicker(null),
      repository,
    );
    addTearDown(controller.dispose);
    controller.initializeExistingImage(
      mediaAssetId: 'existing-media',
      imageUrl: '/uploads/images/existing.jpg',
    );

    await controller.removeImage();

    expect(controller.state.mediaAssetId, isNull);
    expect(controller.state.changeAction, 'REMOVE');
    expect(repository.deletedIds, isEmpty);
  });
}

UserProfileImageUploadInput _input() => UserProfileImageUploadInput(
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
      fileName: 'profile.jpg',
      mimeType: 'image/jpeg',
    );

class _FakePicker implements UserProfileImagePicker {
  _FakePicker(this.input);

  final UserProfileImageUploadInput? input;

  @override
  Future<UserProfileImageUploadInput?> pickImage() async => input;
}

class _FakeRepository implements TenantUserRepository {
  int uploadCount = 0;
  final deletedIds = <String>[];

  @override
  Future<UserProfileImageUpload> uploadProfileImage(
    UserProfileImageUploadInput input, {
    void Function(int sent, int total)? onProgress,
  }) async {
    uploadCount++;
    onProgress?.call(input.bytes.length, input.bytes.length);
    return UserProfileImageUpload(
      mediaAssetId: 'media-1',
      imageUrl: '/uploads/images/profile.jpg',
      originalFileName: input.fileName,
      mimeType: input.mimeType,
      fileSizeBytes: input.bytes.length,
      widthPx: 100,
      heightPx: 100,
    );
  }

  @override
  Future<void> deleteStagedProfileImage(String mediaAssetId) async {
    deletedIds.add(mediaAssetId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
