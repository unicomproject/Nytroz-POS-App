import '../models/tenant_dashboard_dto.dart';
import '../mappers/tenant_dashboard_mapper.dart';

/// Placeholder dashboard payload used only when the backend dashboard API is
/// unavailable (404/501). Remove once `GET /api/v1/tenant-admin/dashboard`
/// is implemented and returns real tenant data.
final tenantAdminDashboardCatalogJson = <String, dynamic>{
  'notificationCount': 0,
  'metrics': [
    {
      'key': 'sales',
      'title': "Today's Sales",
      'value': '--',
      'subtitle': 'Data pending from backend',
      'iconKey': 'sales',
    },
    {
      'key': 'orders',
      'title': 'Orders',
      'value': '--',
      'subtitle': 'Data pending from backend',
      'iconKey': 'orders',
    },
    {
      'key': 'outlets',
      'title': 'Active Outlets',
      'value': '--',
      'subtitle': 'Data pending from backend',
      'iconKey': 'store',
    },
    {
      'key': 'stock',
      'title': 'Stock Alerts',
      'value': '--',
      'subtitle': 'Data pending from backend',
      'iconKey': 'warning',
    },
    {
      'key': 'tills',
      'title': 'Online Tills',
      'value': '--',
      'subtitle': 'Data pending from backend',
      'iconKey': 'till',
    },
  ],
  'salesThisWeek': {
    'title': 'Sales this week',
    'total': '--',
    'subtitle': 'Dashboard API not connected yet',
    'points': [
      {'label': 'Mon', 'value': 0},
      {'label': 'Tue', 'value': 0},
      {'label': 'Wed', 'value': 0},
      {'label': 'Thu', 'value': 0},
      {'label': 'Fri', 'value': 0},
      {'label': 'Sat', 'value': 0},
      {'label': 'Sun', 'value': 0},
    ],
  },
  'needsAttention': [
    {
      'key': 'offline_tills',
      'title': 'Offline tills',
      'message': 'Connect dashboard API for live till status',
      'status': 'warning',
      'route': '/tenant-admin/tills',
    },
    {
      'key': 'low_stock',
      'title': 'Low stock items',
      'message': 'Connect dashboard API for inventory alerts',
      'status': 'warning',
      'route': '/tenant-admin/stock',
    },
    {
      'key': 'pending_invites',
      'title': 'Pending staff invites',
      'message': 'Connect dashboard API for invite status',
      'status': 'pending',
      'route': '/tenant-admin/staff',
    },
    {
      'key': 'payment_due',
      'title': 'Payment due',
      'message': 'Connect dashboard API for billing status',
      'status': 'warning',
      'route': '/tenant-admin/billing',
    },
  ],
  'quickActions': [
    {
      'key': 'add-outlet',
      'title': 'Add outlet',
      'route': '/tenant-admin/outlets/add',
      'featureCode': 'tenant_admin.outlets',
      'permissionCode': 'outlet.create',
      'iconKey': 'store',
    },
    {
      'key': 'add-till',
      'title': 'Add till',
      'route': '/tenant-admin/tills/add',
      'featureCode': 'tenant.tills',
      'permissionCode': 'till.create',
      'iconKey': 'till',
    },
    {
      'key': 'add-staff',
      'title': 'Add staff',
      'route': '/tenant-admin/staff/add',
      'featureCode': 'tenant.users',
      'permissionCode': 'user.create',
      'iconKey': 'users',
    },
    {
      'key': 'add-product',
      'title': 'Add product',
      'route': '/tenant-admin/products/add',
      'featureCode': 'catalog.product',
      'permissionCode': 'product.create',
      'iconKey': 'products',
    },
    {
      'key': 'view-reports',
      'title': 'View reports',
      'route': '/tenant-admin/reports',
      'featureCode': 'reports',
      'permissionCode': 'report.view',
      'iconKey': 'reports',
    },
  ],
  'recentActivity': [
    {
      'key': 'outlet',
      'title': 'Recent activity unavailable',
      'subtitle': 'Dashboard API not connected yet',
      'timeLabel': 'Pending',
      'iconKey': 'store',
    },
  ],
};

TenantDashboardDto get tenantAdminDashboardCatalogFallback =>
    TenantDashboardDto.fromJson(tenantAdminDashboardCatalogJson);
