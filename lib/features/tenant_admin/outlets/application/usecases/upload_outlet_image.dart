import '../../domain/entities/outlet_image_upload.dart';
import '../../domain/repositories/outlet_repository.dart';

class UploadOutletImage {
  const UploadOutletImage(this._repository);
  final OutletRepository _repository;

  Future<OutletImageUpload> call(
    OutletImageUploadInput input, {
    void Function(int sent, int total)? onProgress,
  }) =>
      _repository.uploadOutletImage(input, onProgress: onProgress);
}
