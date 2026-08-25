import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/hardware_device_list_item.dart';
import 'hardware_providers.dart';

final hardwareListProvider =
    FutureProvider.autoDispose<List<HardwareDeviceListItem>>((ref) async {
  final repository = ref.watch(hardwareRepositoryProvider);
  return repository.getHardwareDevices(
    page: 1,
    pageSize: TenantAdminContentTokens.defaultListPageSize,
  );
});
