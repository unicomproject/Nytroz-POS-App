class StagedImageResponseDto {
  final String mediaAssetId;
  final String? publicUrl;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final DateTime createdAt;
  final String status;

  const StagedImageResponseDto({
    required this.mediaAssetId,
    this.publicUrl,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.createdAt,
    required this.status,
  });

  factory StagedImageResponseDto.fromJson(Map<String, dynamic> json) {
    return StagedImageResponseDto(
      mediaAssetId: json['mediaAssetId']?.toString() ?? '',
      publicUrl: json['publicUrl']?.toString(),
      fileName: json['fileName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? 'image/jpeg',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'STAGED',
    );
  }
}
