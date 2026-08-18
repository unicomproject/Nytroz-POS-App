import '../entities/product_wizard_draft.dart';
import '../../data/datasources/product_wizard_draft_local_datasource.dart';

abstract class ProductWizardDraftLocalRepository {
  Future<void> saveDraft(ProductWizardDraft draft);
  Future<ProductWizardDraft?> getDraft(String localDraftId);
  Future<List<ProductWizardDraft>> getAllDrafts();
  Future<void> deleteDraft(String localDraftId);
}

class ProductWizardDraftLocalRepositoryImpl
    implements ProductWizardDraftLocalRepository {
  ProductWizardDraftLocalRepositoryImpl(this._dataSource);

  final ProductWizardDraftLocalDataSource _dataSource;

  @override
  Future<void> saveDraft(ProductWizardDraft draft) =>
      _dataSource.saveDraft(draft);

  @override
  Future<ProductWizardDraft?> getDraft(String localDraftId) =>
      _dataSource.getDraft(localDraftId);

  @override
  Future<List<ProductWizardDraft>> getAllDrafts() => _dataSource.getAllDrafts();

  @override
  Future<void> deleteDraft(String localDraftId) =>
      _dataSource.deleteDraft(localDraftId);
}
