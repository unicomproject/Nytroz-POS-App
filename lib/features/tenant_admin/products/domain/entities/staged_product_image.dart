import 'dart:typed_data';

class StagedProductImage {
  final String mediaAssetId;
  final String? publicUrl;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final DateTime createdAt;
  final String status;
  final bool isPrimary;
  final int sortOrder;
  final Uint8List? bytes;

  const StagedProductImage({
    required this.mediaAssetId,
    this.publicUrl,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.createdAt,
    this.status = 'STAGED',
    this.isPrimary = false,
    this.sortOrder = 0,
    this.bytes,
  });

  StagedProductImage copyWith({
    String? mediaAssetId,
    String? publicUrl,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    DateTime? createdAt,
    String? status,
    bool? isPrimary,
    int? sortOrder,
    Uint8List? bytes,
  }) {
    return StagedProductImage(
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      publicUrl: publicUrl ?? this.publicUrl,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      bytes: bytes ?? this.bytes,
    );
  }
}

class ProductWizardImageItem {
  final String id; // ProductImageId or MediaAssetId
  final String? mediaAssetId;
  final String imageUrl;
  final String fileName;
  final bool isPrimary;
  final int sortOrder;
  final bool isStaged;
  final Uint8List? bytes;

  const ProductWizardImageItem({
    required this.id,
    this.mediaAssetId,
    required this.imageUrl,
    required this.fileName,
    required this.isPrimary,
    required this.sortOrder,
    this.isStaged = false,
    this.bytes,
  });

  ProductWizardImageItem copyWith({
    String? id,
    String? mediaAssetId,
    String? imageUrl,
    String? fileName,
    bool? isPrimary,
    int? sortOrder,
    bool? isStaged,
    Uint8List? bytes,
  }) {
    return ProductWizardImageItem(
      id: id ?? this.id,
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      isStaged: isStaged ?? this.isStaged,
      bytes: bytes ?? this.bytes,
    );
  }
}
