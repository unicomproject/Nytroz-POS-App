import '../entities/product_wizard_draft.dart';
import '../entities/tenant_product.dart';

/// Presentation-layer merge of backend Product rows + local wizard drafts.
///
/// Policy:
/// - Local drafts are prepended on page 1 only (newest first).
/// - Backend [TenantProductListResult.totalCount] is NOT inflated with drafts.
/// - Search matches draft name/code locally.
/// - Status filter: DRAFT shows drafts; ACTIVE/INACTIVE exclude drafts;
///   null/empty status includes drafts.
class ProductListLocalDraftMerger {
  const ProductListLocalDraftMerger._();

  static TenantProductListResult merge({
    required TenantProductListResult backend,
    required List<ProductWizardDraft> drafts,
    required TenantProductListQuery query,
  }) {
    final filtered = drafts.where((d) => _matchesQuery(d, query)).toList();

    if (query.pageNumber != 1 || filtered.isEmpty) {
      return backend;
    }

    final draftRows = filtered.map(toListRow).toList();
    return TenantProductListResult(
      items: [...draftRows, ...backend.items],
      page: backend.page,
      pageSize: backend.pageSize,
      totalCount: backend.totalCount,
      catalogTotalCount: backend.catalogTotalCount,
    );
  }

  static TenantProduct toListRow(ProductWizardDraft draft) {
    final sku = _displaySku(draft);
    return TenantProduct(
      id: draft.localDraftId,
      productCode: draft.productCode ?? '',
      name: draft.productName,
      sku: sku,
      status: 'DRAFT',
      isLocalDraft: true,
      productStructure: draft.productType,
      variantCount: draft.wizardState.step4State.generatedVariants
          .where((v) => v.isIncluded)
          .length
          .clamp(0, 9999),
      priceFrom: draft.wizardState.standardSellingPrice?.toDouble(),
      priceTo: draft.wizardState.standardSellingPrice?.toDouble(),
      primaryBarcode: _displayBarcode(draft),
      imageUrl: _displayImage(draft),
      categoryId: draft.wizardState.categoryId,
      brandId: draft.wizardState.brandId,
      rowVersion: 0,
    );
  }

  static bool _matchesQuery(
    ProductWizardDraft draft,
    TenantProductListQuery query,
  ) {
    final status = query.productStatus?.trim().toUpperCase();
    if (status != null && status.isNotEmpty && status != 'DRAFT') {
      return false;
    }

    // Local drafts have no stock; exclude when a stock filter is active.
    if (query.stockStatus != null && query.stockStatus!.trim().isNotEmpty) {
      return false;
    }

    // Category/brand filters: only match when draft has that id set.
    if (query.categoryId != null &&
        query.categoryId!.isNotEmpty &&
        draft.wizardState.categoryId != query.categoryId) {
      return false;
    }
    if (query.brandId != null &&
        query.brandId!.isNotEmpty &&
        draft.wizardState.brandId != query.brandId) {
      return false;
    }

    final search = query.search?.trim().toLowerCase();
    if (search == null || search.isEmpty) return true;

    final name = draft.productName.toLowerCase();
    final code = (draft.productCode ?? '').toLowerCase();
    final sku = _displaySku(draft).toLowerCase();
    return name.contains(search) ||
        code.contains(search) ||
        sku.contains(search);
  }

  static String _displaySku(ProductWizardDraft draft) {
    final structure = draft.productType.toUpperCase();
    if (structure == 'SIMPLE' || structure == 'BUNDLE') {
      return draft.wizardState.step5State.baseSku;
    }
    final first = draft.wizardState.step5State.assignments
        .where((a) => a.sku != null && a.sku!.trim().isNotEmpty)
        .map((a) => a.sku!.trim())
        .toList();
    return first.isEmpty ? '' : first.first;
  }

  static String? _displayBarcode(ProductWizardDraft draft) {
    final structure = draft.productType.toUpperCase();
    if (structure == 'SIMPLE' || structure == 'BUNDLE') {
      final b = draft.wizardState.step5State.parentProductBarcode.trim();
      return b.isEmpty ? null : b;
    }
    final first = draft.wizardState.step5State.assignments
        .where((a) => a.barcode != null && a.barcode!.trim().isNotEmpty)
        .map((a) => a.barcode!.trim())
        .toList();
    return first.isEmpty ? null : first.first;
  }

  static String? _displayImage(ProductWizardDraft draft) {
    final staged = draft.wizardState.stagedMediaAssets;
    if (staged.isNotEmpty) {
      final primary = staged.where((i) => i.isPrimary).toList();
      final hit = primary.isNotEmpty ? primary.first : staged.first;
      return hit.publicUrl;
    }
    final images = draft.wizardState.productImages;
    if (images.isNotEmpty) {
      final primary = images.where((i) => i.isPrimary).toList();
      final hit = primary.isNotEmpty ? primary.first : images.first;
      return hit.imageUrl.isEmpty ? null : hit.imageUrl;
    }
    return null;
  }
}
