import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../config/till_row_action_configs.dart';

TenantAdminStatusType tillOperationalStatusType(String status) {
  switch (status.toLowerCase()) {
    case 'online':
      return TenantAdminStatusType.active;
    case 'offline':
      return TenantAdminStatusType.inactive;
    case 'needs_attention':
      return TenantAdminStatusType.warning;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    default:
      return TenantAdminStatusType.inactive;
  }
}

String tillOperationalStatusLabel(String status, {String? attentionLabel}) {
  switch (status.toLowerCase()) {
    case 'online':
      return 'Online';
    case 'offline':
      return 'Offline';
    case 'needs_attention':
      return 'Needs attention';
    case 'inactive':
      return 'Inactive';
    default:
      return attentionLabel ?? status;
  }
}

List<TillRowActionConfig> tillInlineActions(TillListVisibility visibility) {
  return visibility.visibleRowActions;
}

List<TillRowActionConfig> tillMoreMenuActions(TillListVisibility visibility) {
  return visibility.visibleMoreMenuActions;
}
