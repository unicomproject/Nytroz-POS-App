import '../../domain/repositories/outlet_repository.dart';

class DeleteStagedOutletImage {
  const DeleteStagedOutletImage(this._repository);
  final OutletRepository _repository;

  Future<void> call(String mediaAssetId) =>
      _repository.deleteStagedOutletImage(mediaAssetId);
}
