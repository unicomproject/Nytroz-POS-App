import '../../domain/entities/outlet_image_upload.dart';

class OutletImageUploadDto {
  const OutletImageUploadDto({
    required this.mediaAssetId,
    required this.imageUrl,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.widthPx,
    required this.heightPx,
  });

  factory OutletImageUploadDto.fromJson(Map<String, dynamic> json) {
    final id = json['mediaAssetId']?.toString();
    final fileName = json['originalFileName']?.toString();
    final mimeType = json['mimeType']?.toString();
    final fileSize = json['fileSizeBytes'];
    if (id == null || id.isEmpty || fileName == null || mimeType == null || fileSize is! num) {
      throw const FormatException('Invalid outlet image upload response.');
    }
    return OutletImageUploadDto(
      mediaAssetId: id,
      imageUrl: json['imageUrl']?.toString(),
      originalFileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: fileSize.toInt(),
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

  OutletImageUpload toEntity() => OutletImageUpload(
        mediaAssetId: mediaAssetId,
        imageUrl: imageUrl,
        originalFileName: originalFileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        widthPx: widthPx,
        heightPx: heightPx,
      );
}
