class TenantAdminPermissionAliases {
  const TenantAdminPermissionAliases._();

  static const Map<String, List<String>> _aliases = {
    'tenant_admin.dashboard.view': [
      'tenant_admin.dashboard.view',
      'dashboard.view',
    ],
    'dashboard.view': [
      'tenant_admin.dashboard.view',
      'dashboard.view',
    ],
    'dashboard.sales_summary.view': [
      'dashboard.sales_summary.view',
      'sales.summary.view',
      'dashboard.summary.view',
    ],
    'sales.summary.view': [
      'dashboard.sales_summary.view',
      'sales.summary.view',
      'dashboard.summary.view',
    ],
    'dashboard.summary.view': [
      'dashboard.sales_summary.view',
      'sales.summary.view',
      'dashboard.summary.view',
    ],
    'dashboard.orders_summary.view': [
      'dashboard.orders_summary.view',
      'sales.orders.view',
      'orders.view',
    ],
    'sales.orders.view': [
      'dashboard.orders_summary.view',
      'sales.orders.view',
      'orders.view',
    ],
    'orders.view': [
      'dashboard.orders_summary.view',
      'sales.orders.view',
      'orders.view',
    ],
    'dashboard.outlet_summary.view': [
      'dashboard.outlet_summary.view',
      'outlets.view',
    ],
    'outlet.view': [
      'dashboard.outlet_summary.view',
      'outlet.view',
      'outlets.view',
    ],
    'outlets.view': [
      'dashboard.outlet_summary.view',
      'outlet.view',
      'outlets.view',
    ],
    'dashboard.stock_alerts.view': [
      'dashboard.stock_alerts.view',
      'inventory.stock_alerts.view',
    ],
    'inventory.stock_alerts.view': [
      'dashboard.stock_alerts.view',
      'inventory.stock_alerts.view',
    ],
    'dashboard.till_status.view': [
      'dashboard.till_status.view',
      'tills.view',
      'tills.status.view',
    ],
    'till.view': [
      'dashboard.till_status.view',
      'till.view',
      'tills.view',
    ],
    'tills.view': [
      'dashboard.till_status.view',
      'till.view',
      'tills.view',
    ],
    'dashboard.sales_chart.view': [
      'dashboard.sales_chart.view',
      'analytics.sales.view',
      'analytics.sales_trend.view',
    ],
    'analytics.sales.view': [
      'dashboard.sales_chart.view',
      'analytics.sales.view',
      'analytics.sales_trend.view',
    ],
    'analytics.sales_trend.view': [
      'dashboard.sales_chart.view',
      'analytics.sales.view',
      'analytics.sales_trend.view',
    ],
    'dashboard.attention.view': [
      'dashboard.attention.view',
      'dashboard.alerts.view',
    ],
    'dashboard.alerts.view': [
      'dashboard.attention.view',
      'dashboard.alerts.view',
    ],
    'dashboard.attention.view_all': [
      'dashboard.attention.view_all',
      'dashboard.alerts.view',
    ],
    'outlet.create': [
      'outlet.create',
      'outlets.create',
    ],
    'outlets.create': [
      'outlet.create',
      'outlets.create',
    ],
    'outlet.summary.view': [
      'outlet.summary.view',
    ],
    'outlet.location_summary.view': [
      'outlet.location_summary.view',
      'outlet.summary.view',
    ],
    'outlet.filter.view': [
      'outlet.filter.view',
    ],
    'outlet.detail.view': [
      'outlet.detail.view',
    ],
    'outlet.location.view': [
      'outlet.location.view',
    ],
    'outlet.status.view': [
      'outlet.status.view',
    ],
    'outlet.sales_summary.view': [
      'outlet.sales_summary.view',
    ],
    'outlet.till_summary.view': [
      'outlet.till_summary.view',
      'till.view',
      'tills.view',
    ],
    'outlet.staff_summary.view': [
      'outlet.staff_summary.view',
      'user.view',
      'users.view',
    ],
    'outlet.update': [
      'outlet.update',
      'outlets.update',
    ],
    'outlet.status.update': [
      'outlet.status.update',
    ],
    'outlet.delete': [
      'outlet.delete',
    ],
    'till.create': [
      'till.create',
      'tills.create',
    ],
    'tills.create': [
      'till.create',
      'tills.create',
    ],
    'till.status.view': [
      'till.status.view',
      'tills.status.view',
    ],
    'tills.status.view': [
      'till.status.view',
      'tills.status.view',
    ],
    'user.view': [
      'user.view',
      'users.view',
    ],
    'users.view': [
      'user.view',
      'users.view',
    ],
    'user.create': [
      'user.create',
      'users.create',
    ],
    'users.create': [
      'user.create',
      'users.create',
    ],
    'user.invite.view': [
      'user.invite.view',
      'users.invites.view',
    ],
    'users.invites.view': [
      'user.invite.view',
      'users.invites.view',
    ],
    'user.invite.create': [
      'user.invite.create',
      'users.invite',
      'users.create',
    ],
    'users.invite': [
      'user.invite.create',
      'users.invite',
      'users.create',
    ],
    'role.view': [
      'role.view',
      'roles.view',
    ],
    'roles.view': [
      'role.view',
      'roles.view',
    ],
    'permission.view': [
      'permission.view',
      'permissions.view',
    ],
    'permissions.view': [
      'permission.view',
      'permissions.view',
    ],
    'roles.permissions.view': [
      'roles.permissions.view',
      'permission.view',
      'permissions.view',
    ],
    'roles.permissions.update': [
      'roles.permissions.update',
    ],
    'product.view': [
      'product.view',
      'products.view',
      'catalog.product.view',
    ],
    'products.view': [
      'product.view',
      'products.view',
      'catalog.product.view',
    ],
    'catalog.product.view': [
      'product.view',
      'products.view',
      'catalog.product.view',
    ],
    'product.create': [
      'product.create',
      'products.create',
      'catalog.product.create',
    ],
    'products.create': [
      'product.create',
      'products.create',
      'catalog.product.create',
    ],
    'catalog.product.create': [
      'product.create',
      'products.create',
      'catalog.product.create',
    ],
    'catalog.product.update': [
      'product.create',
      'product.view',
      'catalog.product.update',
    ],
    'inventory.view': [
      'inventory.view',
    ],
    'inventory.alert.view': [
      'inventory.alert.view',
      'inventory.stock_alerts.view',
    ],
    'report.view': [
      'report.view',
      'reports.view',
    ],
    'reports.view': [
      'report.view',
      'reports.view',
    ],
    'report.sales.view': [
      'report.sales.view',
      'reports.sales.view',
    ],
    'reports.sales.view': [
      'report.sales.view',
      'reports.sales.view',
    ],
    'billing.view': [
      'billing.view',
      'tenant.billing.view',
    ],
    'tenant.billing.view': [
      'billing.view',
      'subscription.view',
      'subscription.billing.view',
      'tenant.billing.view',
    ],
    'subscription.view': [
      'billing.view',
      'subscription.view',
      'subscription.billing.view',
      'tenant.billing.view',
    ],
    'subscription.billing.view': [
      'billing.view',
      'subscription.view',
      'subscription.billing.view',
      'tenant.billing.view',
    ],
    'tenant_settings.view': [
      'tenant_settings.view',
      'settings.view',
      'tenant.settings.manage',
    ],
    'settings.view': [
      'tenant_settings.view',
      'settings.view',
      'tenant.settings.manage',
    ],
    'tenant.settings.manage': [
      'tenant_settings.view',
      'settings.view',
      'tenant.settings.manage',
    ],
    'activity_log.view': [
      'activity_log.view',
      'activity.view',
      'audit_logs.view',
      'tenant.activity.view',
    ],
    'activity.view': [
      'activity_log.view',
      'activity.view',
      'audit_logs.view',
      'tenant.activity.view',
    ],
    'audit_logs.view': [
      'activity_log.view',
      'activity.view',
      'audit_logs.view',
      'tenant.activity.view',
    ],
    'tenant.activity.view': [
      'activity_log.view',
      'activity.view',
      'audit_logs.view',
      'tenant.activity.view',
    ],
    'activity_log.detail.view': [
      'activity_log.detail.view',
    ],
    'notification.view': [
      'notification.view',
      'notifications.view',
    ],
    'notifications.view': [
      'notification.view',
      'notifications.view',
    ],
    'notification.read': [
      'notification.read',
    ],
    'support.view': [
      'support.view',
    ],
    'tenant.till.manage': [
      'tills.view',
      'tills.create',
      'tills.status.view',
      'till.view',
      'till.create',
      'till.status.view',
      'tenant.till.manage',
    ],
    'tenant.user.manage': [
      'users.view',
      'users.create',
      'users.invite',
      'users.invites.view',
      'users.activity.view',
      'user.view',
      'user.create',
      'user.invite.view',
      'user.invite.create',
      'tenant.user.manage',
    ],
    'tenant.role.manage': [
      'roles.view',
      'permissions.view',
      'role.view',
      'permission.view',
      'tenant.role.manage',
    ],
    'outlets.update': [
      'outlets.create',
      'outlets.view',
      'outlet.create',
      'outlet.view',
      'outlets.update',
      'outlet.update',
    ],
    'inventory.adjust': [
      'inventory.view',
      'inventory.adjust',
    ],
    'tenant.product.import': [
      'products.view',
      'products.create',
      'product.view',
      'product.create',
      'tenant.product.import',
    ],
  };

  static Iterable<String> expand(String permissionCode) {
    final aliases = _aliases[permissionCode];
    if (aliases == null || aliases.isEmpty) {
      return [permissionCode];
    }

    return aliases;
  }
}
