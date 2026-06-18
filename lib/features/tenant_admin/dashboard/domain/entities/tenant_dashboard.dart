class TenantDashboard {
  const TenantDashboard({
    required this.metrics,
    required this.salesThisWeek,
    required this.needsAttention,
    required this.quickActions,
    required this.recentActivity,
    this.notificationCount,
  });

  final List<TenantDashboardMetric> metrics;
  final TenantDashboardSalesSummary? salesThisWeek;
  final List<TenantDashboardAttentionItem> needsAttention;
  final List<TenantDashboardQuickAction> quickActions;
  final List<TenantDashboardActivity> recentActivity;
  final int? notificationCount;

  bool get isEmpty {
    return metrics.isEmpty &&
        salesThisWeek == null &&
        needsAttention.isEmpty &&
        quickActions.isEmpty &&
        recentActivity.isEmpty;
  }
}

class TenantDashboardMetric {
  const TenantDashboardMetric({
    required this.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.iconKey,
    this.trend,
    this.status,
  });

  final String key;
  final String title;
  final String value;
  final String? subtitle;
  final String? iconKey;
  final String? trend;
  final String? status;
}

class TenantDashboardSalesSummary {
  const TenantDashboardSalesSummary({
    required this.title,
    required this.total,
    required this.points,
    this.subtitle,
  });

  final String title;
  final String total;
  final String? subtitle;
  final List<TenantDashboardChartPoint> points;
}

class TenantDashboardChartPoint {
  const TenantDashboardChartPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class TenantDashboardAttentionItem {
  const TenantDashboardAttentionItem({
    required this.key,
    required this.title,
    required this.message,
    this.status,
    this.route,
  });

  final String key;
  final String title;
  final String message;
  final String? status;
  final String? route;
}

class TenantDashboardQuickAction {
  const TenantDashboardQuickAction({
    required this.key,
    required this.title,
    required this.route,
    required this.featureCode,
    required this.permissionCode,
    this.subtitle,
    this.iconKey,
  });

  final String key;
  final String title;
  final String? subtitle;
  final String route;
  final String? iconKey;
  final String featureCode;
  final String permissionCode;
}

class TenantDashboardActivity {
  const TenantDashboardActivity({
    required this.key,
    required this.title,
    required this.timeLabel,
    this.subtitle,
    this.iconKey,
  });

  final String key;
  final String title;
  final String? subtitle;
  final String timeLabel;
  final String? iconKey;
}
