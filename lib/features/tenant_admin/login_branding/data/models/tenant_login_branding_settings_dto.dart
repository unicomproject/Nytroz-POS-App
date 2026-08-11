import '../../../../auth/data/models/pos_login_branding_dto.dart';
import '../../../../auth/domain/entities/pos_login_branding.dart';
import '../../domain/entities/tenant_login_branding_settings.dart';

class TenantLoginBrandingSettingsDto {
  const TenantLoginBrandingSettingsDto(this.json);

  final Map<String, dynamic> json;

  TenantLoginBrandingSettings toDomain() {
    final configured = _map(json['configured']);
    final effective = _map(json['effective']);
    return TenantLoginBrandingSettings(
      systemName: _optional(configured, 'systemName'),
      description: _optional(configured, 'description'),
      subtitleTemplate: _optional(configured, 'subtitleTemplate'),
      backgroundMode: _mode(_optional(configured, 'backgroundMode')),
      backgroundColor: _optional(configured, 'backgroundColor'),
      backgroundMediaAssetId: _optional(configured, 'backgroundMediaAssetId'),
      heroMediaAssetId: _optional(configured, 'heroMediaAssetId'),
      effective: PosLoginBrandingDto(effective).toDomain(),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static String? _optional(Map<String, dynamic> source, String key) {
    final value = source[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static PosLoginBackgroundMode? _mode(String? value) {
    if (value == null) return null;
    return value.toUpperCase() == 'IMAGE'
        ? PosLoginBackgroundMode.image
        : PosLoginBackgroundMode.color;
  }
}
