import '../entities/outlet.dart';
import '../entities/outlet_create_options.dart';
import '../entities/outlet_detail_entities.dart';
import '../entities/outlet_details.dart';
import '../entities/outlet_list_query.dart';

abstract class OutletRepository {
  Future<OutletListResult> getOutlets({required OutletListQuery query});

  Future<OutletSummaryDashboard> getSummary();

  Future<OutletCreateOptions> getCreateOptions();

  Future<OutletDetails> getOutletDetails(String id);

  Future<TenantAdminOutletOverview> getTenantAdminOverview(String id);

  Future<OutletDetail> getOutletDetail(String id);

  Future<OutletRevenueSummary> getOutletRevenueSummary(String id);

  Future<OutletAssignedUsersResult> getOutletAssignedUsers(String id);

  Future<OutletTillsDetailResult> getOutletTillsDetail(String id);

  Future<OutletDetails> createOutlet(OutletFormData form);

  Future<OutletDetails> updateOutlet(String id, OutletFormData form);

  Future<void> updateOutletStatus(String id, String status);

  Future<void> deleteOutlet(String id);

  Future<List<OutletManagerOption>> getManagerOptions();
}
