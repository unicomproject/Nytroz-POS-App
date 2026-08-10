import 'dart:typed_data';

class OutletImageUpload {
  const OutletImageUpload({
    required this.mediaAssetId,
    required this.imageUrl,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.widthPx,
    required this.heightPx,
  });

  final String mediaAssetId;
  final String? imageUrl;
  final String originalFileName;
  final String mimeType;
  final int fileSizeBytes;
  final int? widthPx;
  final int? heightPx;
}

class OutletImageUploadInput {
  const OutletImageUploadInput({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}
