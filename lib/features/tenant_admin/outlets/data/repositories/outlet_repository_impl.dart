import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_details.dart';
import '../../domain/repositories/outlet_repository.dart';
import '../datasources/outlet_remote_datasource.dart';
import '../mappers/outlet_mapper.dart';
import '../models/create_outlet_request_dto.dart';

class OutletRepositoryImpl implements OutletRepository {
  const OutletRepositoryImpl(this._remoteDatasource);

  final OutletRemoteDatasource _remoteDatasource;

  @override
  Future<OutletListResult> getOutlets({String? search}) async {
    final dto = await _remoteDatasource.getOutlets(search: search);
    return dto.toEntity();
  }

  @override
  Future<OutletDetails> getOutletDetails(String id) async {
    final dto = await _remoteDatasource.getOutletDetails(id);
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
  Future<List<OutletManagerOption>> getManagerOptions() async {
    final dtos = await _remoteDatasource.getManagerOptions();
    return dtos.map((manager) => manager.toEntity()).toList(growable: false);
  }
}
