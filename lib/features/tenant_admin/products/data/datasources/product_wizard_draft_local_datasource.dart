import 'dart:convert';

import 'package:nytroz_pos/core/storage/app_secure_storage.dart';

import '../../domain/entities/product_wizard_draft.dart';

/// Local persistence for Product Wizard drafts.
///
/// Uses [AppSecureStorage] (project-standard `flutter_secure_storage`) so drafts
/// work on web and native without adding a new package.
abstract class ProductWizardDraftLocalDataSource {
  Future<void> saveDraft(ProductWizardDraft draft);
  Future<ProductWizardDraft?> getDraft(String localDraftId);
  Future<List<ProductWizardDraft>> getAllDrafts();
  Future<void> deleteDraft(String localDraftId);
}

class ProductWizardDraftLocalDataSourceImpl
    implements ProductWizardDraftLocalDataSource {
  ProductWizardDraftLocalDataSourceImpl(this._storage);

  final AppSecureStorage _storage;

  static const _indexKey = 'product_wizard_local_draft_index_v1';
  static String _draftKey(String localDraftId) =>
      'product_wizard_local_draft_v1_$localDraftId';

  @override
  Future<void> saveDraft(ProductWizardDraft draft) async {
    if (draft.localDraftId.isEmpty) {
      throw ArgumentError('localDraftId is required');
    }

    final payload = jsonEncode(draft.toJson());
    await _storage.write(_draftKey(draft.localDraftId), payload);

    final ids = await _readIndex();
    if (!ids.contains(draft.localDraftId)) {
      ids.add(draft.localDraftId);
      await _writeIndex(ids);
    }
  }

  @override
  Future<ProductWizardDraft?> getDraft(String localDraftId) async {
    if (localDraftId.isEmpty) return null;
    final raw = await _storage.read(_draftKey(localDraftId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ProductWizardDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProductWizardDraft>> getAllDrafts() async {
    final ids = await _readIndex();
    final drafts = <ProductWizardDraft>[];
    final surviving = <String>[];

    for (final id in ids) {
      final draft = await getDraft(id);
      if (draft == null) continue;
      drafts.add(draft);
      surviving.add(id);
    }

    if (surviving.length != ids.length) {
      await _writeIndex(surviving);
    }

    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  @override
  Future<void> deleteDraft(String localDraftId) async {
    if (localDraftId.isEmpty) return;
    await _storage.delete(_draftKey(localDraftId));
    final ids = await _readIndex();
    ids.remove(localDraftId);
    await _writeIndex(ids);
  }

  Future<List<String>> _readIndex() async {
    final raw = await _storage.read(_indexKey);
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>[];
      return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> _writeIndex(List<String> ids) async {
    await _storage.write(_indexKey, jsonEncode(ids));
  }
}

/// In-memory implementation for unit tests.
class InMemoryProductWizardDraftLocalDataSource
    implements ProductWizardDraftLocalDataSource {
  final Map<String, ProductWizardDraft> _store = {};

  @override
  Future<void> saveDraft(ProductWizardDraft draft) async {
    _store[draft.localDraftId] = draft;
  }

  @override
  Future<ProductWizardDraft?> getDraft(String localDraftId) async {
    return _store[localDraftId];
  }

  @override
  Future<List<ProductWizardDraft>> getAllDrafts() async {
    final list = _store.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> deleteDraft(String localDraftId) async {
    _store.remove(localDraftId);
  }
}
