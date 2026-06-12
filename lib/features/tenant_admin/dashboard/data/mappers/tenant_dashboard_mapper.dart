import '../../domain/entities/tenant_dashboard.dart';
import '../models/tenant_dashboard_dto.dart';

extension TenantDashboardMapper on TenantDashboardDto {
  TenantDashboard toEntity() {
    return TenantDashboard(
      metrics: metrics.map((metric) => metric.toEntity()).toList(),
      salesThisWeek: salesThisWeek?.toEntity(),
      needsAttention: needsAttention.map((item) => item.toEntity()).toList(),
      quickActions: quickActions.map((action) => action.toEntity()).toList(),
      recentActivity:
          recentActivity.map((activity) => activity.toEntity()).toList(),
    );
  }
}

extension TenantDashboardMetricMapper on TenantDashboardMetricDto {
  TenantDashboardMetric toEntity() {
    return TenantDashboardMetric(
      key: key,
      title: title,
      value: value,
      subtitle: subtitle,
      iconKey: iconKey,
      trend: trend,
      status: status,
    );
  }
}

extension TenantDashboardSalesSummaryMapper on TenantDashboardSalesSummaryDto {
  TenantDashboardSalesSummary toEntity() {
    return TenantDashboardSalesSummary(
      title: title,
      total: total,
      subtitle: subtitle,
      points: points.map((point) => point.toEntity()).toList(),
    );
  }
}

extension TenantDashboardChartPointMapper on TenantDashboardChartPointDto {
  TenantDashboardChartPoint toEntity() {
    return TenantDashboardChartPoint(
      label: label,
      value: value,
    );
  }
}

extension TenantDashboardAttentionItemMapper
    on TenantDashboardAttentionItemDto {
  TenantDashboardAttentionItem toEntity() {
    return TenantDashboardAttentionItem(
      title: title,
      message: message,
      status: status,
      route: route,
    );
  }
}

extension TenantDashboardQuickActionMapper on TenantDashboardQuickActionDto {
  TenantDashboardQuickAction toEntity() {
    return TenantDashboardQuickAction(
      key: key,
      title: title,
      subtitle: subtitle,
      route: route,
      iconKey: iconKey,
      featureCode: featureCode,
      permissionCode: permissionCode,
    );
  }
}

extension TenantDashboardActivityMapper on TenantDashboardActivityDto {
  TenantDashboardActivity toEntity() {
    return TenantDashboardActivity(
      title: title,
      subtitle: subtitle,
      timeLabel: timeLabel,
      iconKey: iconKey,
    );
  }
}
