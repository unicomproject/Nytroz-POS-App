class TenantAdminMenuItemDto {
  const TenantAdminMenuItemDto({
    required this.key,
    required this.label,
    required this.route,
    required this.iconKey,
    required this.featureCode,
    required this.permissionCode,
    required this.visible,
    required this.order,
  });

  factory TenantAdminMenuItemDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminMenuItemDto(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      route: json['route'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
      featureCode: json['featureCode'] as String? ?? '',
      permissionCode: json['permissionCode'] as String? ?? '',
      visible: json['visible'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  final String key;
  final String label;
  final String route;
  final String iconKey;
  final String featureCode;
  final String permissionCode;
  final bool visible;
  final int order;
}
