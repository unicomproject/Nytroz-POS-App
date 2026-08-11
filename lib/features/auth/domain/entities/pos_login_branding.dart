enum PosLoginBackgroundMode { color, image }

class PosLoginBranding {
  const PosLoginBranding({
    required this.tenantSlug,
    required this.brandDisplayName,
    required this.systemName,
    required this.description,
    required this.loginSubtitle,
    required this.backgroundMode,
    required this.backgroundColor,
    required this.updatedAt,
    this.logoUrl,
    this.backgroundImageUrl,
    this.heroImageUrl,
  });

  /// Empty shell used only while backend branding is loading.
  /// Do not use local packaged artwork as a substitute for API branding.
  static final unloaded = PosLoginBranding(
    tenantSlug: '',
    brandDisplayName: '',
    systemName: '',
    description: '',
    loginSubtitle: 'Sign in',
    backgroundMode: PosLoginBackgroundMode.color,
    backgroundColor: '#000E2B',
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  /// Field-level defaults when a backend payload omits optional text fields.
  static final packagedDefault = PosLoginBranding(
    tenantSlug: '',
    brandDisplayName: 'OneVerz',
    systemName: 'Smart Cashier System',
    description: 'Powering every sale.\nEvery venue. Every day.',
    loginSubtitle: 'Sign in to continue to OneVerz POS',
    backgroundMode: PosLoginBackgroundMode.color,
    backgroundColor: '#000E2B',
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final String tenantSlug;
  final String brandDisplayName;
  final String systemName;
  final String description;
  final String loginSubtitle;
  final PosLoginBackgroundMode backgroundMode;
  final String backgroundColor;
  final String? logoUrl;
  final String? backgroundImageUrl;
  final String? heroImageUrl;
  final DateTime updatedAt;

  bool get hasBackendMedia =>
      (logoUrl?.trim().isNotEmpty ?? false) ||
      (heroImageUrl?.trim().isNotEmpty ?? false) ||
      (backgroundImageUrl?.trim().isNotEmpty ?? false);

  PosLoginBranding copyWith({
    String? tenantSlug,
    String? brandDisplayName,
    String? systemName,
    String? description,
    String? loginSubtitle,
    PosLoginBackgroundMode? backgroundMode,
    String? backgroundColor,
    String? logoUrl,
    String? backgroundImageUrl,
    String? heroImageUrl,
    DateTime? updatedAt,
  }) =>
      PosLoginBranding(
        tenantSlug: tenantSlug ?? this.tenantSlug,
        brandDisplayName: brandDisplayName ?? this.brandDisplayName,
        systemName: systemName ?? this.systemName,
        description: description ?? this.description,
        loginSubtitle: loginSubtitle ?? this.loginSubtitle,
        backgroundMode: backgroundMode ?? this.backgroundMode,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        logoUrl: logoUrl ?? this.logoUrl,
        backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
        heroImageUrl: heroImageUrl ?? this.heroImageUrl,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

extension PosLoginColor on String {
  int? get posLoginColorValue {
    final value = trim().toUpperCase();
    if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(value)) return null;
    return int.parse('FF${value.substring(1)}', radix: 16);
  }
}
