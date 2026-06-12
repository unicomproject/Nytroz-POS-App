import '../entities/outlet.dart';
import '../entities/outlet_details.dart';

abstract class OutletRepository {
  Future<OutletListResult> getOutlets({String? search});

  Future<OutletDetails> getOutletDetails(String id);

  Future<OutletDetails> createOutlet(OutletFormData form);

  Future<OutletDetails> updateOutlet(String id, OutletFormData form);

  Future<void> updateOutletStatus(String id, String status);

  Future<List<OutletManagerOption>> getManagerOptions();
}
