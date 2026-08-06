import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_create_options.dart';
import '../../domain/entities/outlet_detail_entities.dart';
import '../../domain/entities/outlet_details.dart';
import '../../domain/entities/outlet_list_query.dart';
import '../../domain/repositories/outlet_repository.dart';
import '../datasources/outlet_remote_datasource.dart';
import '../mappers/outlet_mapper.dart';
import '../models/create_outlet_request_dto.dart';

class OutletRepositoryImpl implements OutletRepository {
  const OutletRepositoryImpl(this._remoteDatasource);

  final OutletRemoteDatasource _remoteDatasource;

  @override
  Future<OutletListResult> getOutlets({required OutletListQuery query}) async {
    final dto = await _remoteDatasource.getOutlets(query);
    return dto.toEntity();
  }

  @override
  Future<OutletSummaryDashboard> getSummary() async {
    final dto = await _remoteDatasource.getSummary();
    return dto.toEntity();
  }

  @override
  Future<OutletCreateOptions> getCreateOptions() async {
    final dto = await _remoteDatasource.getCreateOptions();
    return dto.toEntity();
  }

  @override
  Future<OutletDetails> getOutletDetails(String id) async {
    final dto = await _remoteDatasource.getOutletDetails(id);
    return dto.toEntity();
  }

  @override
  Future<TenantAdminOutletOverview> getTenantAdminOverview(String id) async {
    final dto = await _remoteDatasource.getTenantAdminOverview(id);
    return dto.toEntity();
  }

  @override
  Future<OutletDetail> getOutletDetail(String id) async {
    final dto = await _remoteDatasource.getOutletDetail(id);
    return dto.toEntity();
  }

  @override
  Future<OutletRevenueSummary> getOutletRevenueSummary(String id) async {
    final dto = await _remoteDatasource.getOutletRevenueSummary(id);
    return dto.toEntity();
  }

  @override
  Future<OutletAssignedUsersResult> getOutletAssignedUsers(String id) async {
    final dto = await _remoteDatasource.getOutletAssignedUsers(id);
    return dto.toEntity();
  }

  @override
  Future<OutletTillsDetailResult> getOutletTillsDetail(String id) async {
    final dto = await _remoteDatasource.getOutletTillsDetail(id);
    return dto.toEntity();
  }

  @override
  Future<OutletDetails> createOutlet(OutletFormData form) async {
    final dto = await _remoteDatasource.createOutlet(
      CreateOutletRequestDto.fromForm(form),
    );
    return dto.toEntity();
  }

  @override
  Future<OutletDetails> updateOutlet(String id, OutletFormData form) async {
    final dto = await _remoteDatasource.updateOutlet(
      id,
      CreateOutletRequestDto.fromForm(form),
    );
    return dto.toEntity();
  }

  @override
  Future<void> updateOutletStatus(String id, String status) {
    return _remoteDatasource.updateOutletStatus(id, status);
  }

  @override
  Future<void> deleteOutlet(String id) {
    return _remoteDatasource.deleteOutlet(id);
  }

  @override
  Future<List<OutletManagerOption>> getManagerOptions() async {
    final dtos = await _remoteDatasource.getManagerOptions();
    return dtos.map((manager) => manager.toEntity()).toList(growable: false);
  }
}
