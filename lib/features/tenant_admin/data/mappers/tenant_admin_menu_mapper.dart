import '../../domain/entities/tenant_admin_menu_item.dart';
import '../models/tenant_admin_menu_item_dto.dart';

extension TenantAdminMenuMapper on TenantAdminMenuItemDto {
  TenantAdminMenuItem toEntity() {
    return TenantAdminMenuItem(
      key: key,
      label: label,
      route: route,
      iconKey: iconKey,
      featureCode: featureCode,
      permissionCode: permissionCode,
      visible: visible,
      order: order,
    );
  }
}
