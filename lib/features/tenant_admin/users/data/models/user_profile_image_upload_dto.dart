import '../../domain/entities/user_profile_image_upload.dart';

class UserProfileImageUploadDto {
  const UserProfileImageUploadDto({
    required this.mediaAssetId,
    required this.imageUrl,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.widthPx,
    required this.heightPx,
  });

  factory UserProfileImageUploadDto.fromJson(Map<String, dynamic> json) {
    final mediaAssetId = json['mediaAssetId']?.toString();
    final originalFileName = json['originalFileName']?.toString();
    final mimeType = json['mimeType']?.toString();
    final fileSizeBytes = json['fileSizeBytes'];
    if (mediaAssetId == null ||
        mediaAssetId.isEmpty ||
        originalFileName == null ||
        mimeType == null ||
        fileSizeBytes is! num) {
      throw const FormatException('Invalid user profile image response.');
    }

    return UserProfileImageUploadDto(
      mediaAssetId: mediaAssetId,
      imageUrl: json['imageUrl']?.toString(),
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes.toInt(),
      widthPx: (json['widthPx'] as num?)?.toInt(),
      heightPx: (json['heightPx'] as num?)?.toInt(),
    );
  }

  final String mediaAssetId;
  final String? imageUrl;
  final String originalFileName;
  final String mimeType;
  final int fileSizeBytes;
  final int? widthPx;
  final int? heightPx;

  UserProfileImageUpload toEntity() => UserProfileImageUpload(
        mediaAssetId: mediaAssetId,
        imageUrl: imageUrl,
        originalFileName: originalFileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        widthPx: widthPx,
        heightPx: heightPx,
      );
}
