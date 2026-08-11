import '../../../../auth/domain/entities/pos_login_branding.dart';
import 'dart:typed_data';

class TenantLoginBrandingMediaInput {
  const TenantLoginBrandingMediaInput({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class TenantLoginBrandingMediaUpload {
  const TenantLoginBrandingMediaUpload({
    required this.mediaAssetId,
    required this.purpose,
    required this.publicUrl,
  });

  final String mediaAssetId;
  final String purpose;
  final String? publicUrl;
}

class TenantLoginBrandingSettings {
  const TenantLoginBrandingSettings({
    required this.effective,
    this.systemName,
    this.description,
    this.subtitleTemplate,
    this.backgroundMode,
    this.backgroundColor,
    this.backgroundMediaAssetId,
    this.heroMediaAssetId,
  });

  final String? systemName;
  final String? description;
  final String? subtitleTemplate;
  final PosLoginBackgroundMode? backgroundMode;
  final String? backgroundColor;
  final String? backgroundMediaAssetId;
  final String? heroMediaAssetId;
  final PosLoginBranding effective;
}

class UpdateTenantLoginBrandingSettings {
  const UpdateTenantLoginBrandingSettings({
    this.systemName,
    this.description,
    this.subtitleTemplate,
    this.backgroundMode,
    this.backgroundColor,
    this.backgroundMediaAssetId,
    this.heroMediaAssetId,
  });

  final String? systemName;
  final String? description;
  final String? subtitleTemplate;
  final PosLoginBackgroundMode? backgroundMode;
  final String? backgroundColor;
  final String? backgroundMediaAssetId;
  final String? heroMediaAssetId;

  Map<String, dynamic> toJson() => {
        'systemName': systemName,
        'description': description,
        'subtitleTemplate': subtitleTemplate,
        'backgroundMode': backgroundMode?.name.toUpperCase(),
        'backgroundColor': backgroundColor,
        'backgroundMediaAssetId': backgroundMediaAssetId,
        'heroMediaAssetId': heroMediaAssetId,
      };
}
