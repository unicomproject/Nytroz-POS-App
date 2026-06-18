class TenantDashboardDto {
  const TenantDashboardDto({
    required this.metrics,
    required this.salesThisWeek,
    required this.needsAttention,
    required this.quickActions,
    required this.recentActivity,
    this.notificationCount,
  });

  factory TenantDashboardDto.fromJson(Map<String, dynamic> json) {
    return TenantDashboardDto(
      metrics: _mapList(json['metrics'], TenantDashboardMetricDto.fromJson),
      salesThisWeek: json['salesThisWeek'] is Map
          ? TenantDashboardSalesSummaryDto.fromJson(
              Map<String, dynamic>.from(json['salesThisWeek'] as Map),
            )
          : null,
      needsAttention: _mapList(
        json['needsAttention'],
        TenantDashboardAttentionItemDto.fromJson,
      ),
      quickActions: _mapList(
        json['quickActions'],
        TenantDashboardQuickActionDto.fromJson,
      ),
      recentActivity: _mapList(
        json['recentActivity'],
        TenantDashboardActivityDto.fromJson,
      ),
      notificationCount: _intValue(json['notificationCount']),
    );
  }

  final List<TenantDashboardMetricDto> metrics;
  final TenantDashboardSalesSummaryDto? salesThisWeek;
  final List<TenantDashboardAttentionItemDto> needsAttention;
  final List<TenantDashboardQuickActionDto> quickActions;
  final List<TenantDashboardActivityDto> recentActivity;
  final int? notificationCount;
}

class TenantDashboardMetricDto {
  const TenantDashboardMetricDto({
    required this.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.iconKey,
    this.trend,
    this.status,
  });

  factory TenantDashboardMetricDto.fromJson(Map<String, dynamic> json) {
    return TenantDashboardMetricDto(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      value: json['value']?.toString() ?? '',
      subtitle: json['subtitle'] as String?,
      iconKey: json['iconKey'] as String?,
      trend: json['trend'] as String?,
      status: json['status'] as String?,
    );
  }

  final String key;
  final String title;
  final String value;
  final String? subtitle;
  final String? iconKey;
  final String? trend;
  final String? status;
}

class TenantDashboardSalesSummaryDto {
  const TenantDashboardSalesSummaryDto({
    required this.title,
    required this.total,
    required this.points,
    this.subtitle,
  });

  factory TenantDashboardSalesSummaryDto.fromJson(Map<String, dynamic> json) {
    return TenantDashboardSalesSummaryDto(
      title: json['title'] as String? ?? 'Sales this week',
      total: json['total']?.toString() ?? '',
      subtitle: json['subtitle'] as String?,
      points: _mapList(json['points'], TenantDashboardChartPointDto.fromJson),
    );
  }

  final String title;
  final String total;
  final String? subtitle;
  final List<TenantDashboardChartPointDto> points;
}

class TenantDashboardChartPointDto {
  const TenantDashboardChartPointDto({
    required this.label,
    required this.value,
  });

  factory TenantDashboardChartPointDto.fromJson(Map<String, dynamic> json) {
    return TenantDashboardChartPointDto(
      label: json['label'] as String? ?? '',
      value: _doubleValue(json['value']),
    );
  }

  final String label;
  final double value;
}

class TenantDashboardAttentionItemDto {
  const TenantDashboardAttentionItemDto({
    required this.key,
    required this.title,
    required this.message,
    this.status,
    this.route,
  });

  factory TenantDashboardAttentionItemDto.fromJson(Map<String, dynamic> json) {
    return TenantDashboardAttentionItemDto(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String?,
      route: json['route'] as String?,
    );
  }

  final String key;
  final String title;
  final String message;
  final String? status;
  final String? route;
}

class TenantDashboardQuickActionDto {
  const TenantDashboardQuickActionDto({
    required this.key,
    required this.title,
    required this.route,
    required this.featureCode,
    required this.permissionCode,
    this.subtitle,
    this.iconKey,
  });

  factory TenantDashboardQuickActionDto.fromJson(Map<String, dynamic> json) {
    return TenantDashboardQuickActionDto(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      route: json['route'] as String? ?? '',
      iconKey: json['iconKey'] as String?,
      featureCode: json['featureCode'] as String? ?? '',
      permissionCode: json['permissionCode'] as String? ?? '',
    );
  }

  final String key;
  final String title;
  final String? subtitle;
  final String route;
  final String? iconKey;
  final String featureCode;
  final String permissionCode;
}

class TenantDashboardActivityDto {
  const TenantDashboardActivityDto({
    required this.key,
    required this.title,
    required this.timeLabel,
    this.subtitle,
    this.iconKey,
  });

  factory TenantDashboardActivityDto.fromJson(Map<String, dynamic> json) {
    return TenantDashboardActivityDto(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      timeLabel: json['timeLabel'] as String? ?? '',
      iconKey: json['iconKey'] as String?,
    );
  }

  final String key;
  final String title;
  final String? subtitle;
  final String timeLabel;
  final String? iconKey;
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _intValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}
