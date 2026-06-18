import '../entities/outlet.dart';
import '../entities/outlet_details.dart';
import '../entities/outlet_list_query.dart';

abstract class OutletRepository {
  Future<OutletListResult> getOutlets({required OutletListQuery query});

  Future<OutletDetails> getOutletDetails(String id);

  Future<OutletDetails> createOutlet(OutletFormData form);

  Future<OutletDetails> updateOutlet(String id, OutletFormData form);

  Future<void> updateOutletStatus(String id, String status);

  Future<void> deleteOutlet(String id);

  Future<List<OutletManagerOption>> getManagerOptions();
}
