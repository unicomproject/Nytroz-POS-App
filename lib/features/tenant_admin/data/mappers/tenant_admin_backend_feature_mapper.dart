import '../../../../core/access/tenant_admin_access_codes.dart';

class TenantAdminBackendFeatureMapper {
  const TenantAdminBackendFeatureMapper._();

  static String toAppFeatureCode(String backendFeatureKey) {
    switch (backendFeatureKey) {
      case 'dashboard':
        return TenantAdminFeatureCodes.dashboard;
      case 'outlet_management':
        return TenantAdminFeatureCodes.outletManagement;
      case 'till_management':
        return TenantAdminFeatureCodes.tillManagement;
      case 'staff_management':
        return TenantAdminFeatureCodes.staffManagement;
      case 'role_permission':
        return TenantAdminFeatureCodes.rolePermission;
      case 'product_management':
        return TenantAdminFeatureCodes.productManagement;
      case 'inventory_management':
        return TenantAdminFeatureCodes.inventoryManagement;
      case 'reports_analytics':
        return TenantAdminFeatureCodes.reportsAnalytics;
      case 'billing_subscription':
        return TenantAdminFeatureCodes.billingSubscription;
      case 'activity_audit':
        return TenantAdminFeatureCodes.activityAudit;
      case 'tenant_settings':
        return TenantAdminFeatureCodes.tenantSettings;
      case 'support':
        return TenantAdminFeatureCodes.support;
      case 'sales':
        return TenantAdminFeatureCodes.sales;
      default:
        return backendFeatureKey;
    }
  }
}
