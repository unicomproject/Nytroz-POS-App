import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/staged_product_image.dart';

/// Projection of the just-created product for the Step 7 success screen.
/// Values come from wizard state after backend create — no sample data.
class ProductCreateSuccessSnapshot {
  const ProductCreateSuccessSnapshot({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.sku,
    required this.status,
    required this.productStructure,
    required this.totalSkus,
    required this.createdAt,
    this.totalVariants,
    this.primaryImage,
  });

  final String productId;
  final String productName;
  final String productCode;
  final String sku;
  final String status;
  final String productStructure;
  final int totalSkus;
  final int? totalVariants;
  final DateTime createdAt;
  final ProductWizardImageItem? primaryImage;

  bool get isVariant => productStructure.toUpperCase() == 'VARIANT';

  String get productTypeLabel {
    switch (productStructure.toUpperCase()) {
      case 'VARIANT':
        return 'Variant Product';
      case 'BUNDLE':
        return 'Bundle / Kit';
      case 'SIMPLE':
      default:
        return 'Simple Product';
    }
  }

  String get statusLabel {
    final raw = status.trim();
    if (raw.isEmpty) return '—';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  String get skuOrCodeDisplay {
    if (sku.trim().isNotEmpty) return sku.trim();
    if (productCode.trim().isNotEmpty) return productCode.trim();
    return '—';
  }

  factory ProductCreateSuccessSnapshot.fromWizard(
    AddProductWizardState state, {
    DateTime? createdAt,
  }) {
    final structure = state.productStructure.toUpperCase();
    final isVariant = structure == 'VARIANT';
    final included = state.step4State.generatedVariants
        .where((v) => v.isIncluded)
        .toList();
    final skuCount = isVariant
        ? state.step5State.assignments
            .where((a) => (a.sku ?? '').trim().isNotEmpty)
            .length
        : (state.step5State.baseSku.trim().isNotEmpty ||
                state.internalCode.trim().isNotEmpty
            ? 1
            : 0);

    ProductWizardImageItem? primary;
    for (final img in state.productImages) {
      if (img.isPrimary) {
        primary = img;
        break;
      }
    }
    primary ??= state.productImages.isEmpty ? null : state.productImages.first;

    final simpleSku = state.step5State.baseSku.trim();
    final code = state.internalCode.trim();
    String variantSku = '';
    for (final a in state.step5State.assignments) {
      if ((a.sku ?? '').trim().isNotEmpty) {
        variantSku = a.sku!.trim();
        break;
      }
    }

    return ProductCreateSuccessSnapshot(
      productId: state.productId ?? '',
      productName: state.productName.trim(),
      productCode: code,
      sku: isVariant
          ? (code.isNotEmpty ? code : variantSku)
          : (simpleSku.isNotEmpty ? simpleSku : code),
      status: state.status,
      productStructure: structure,
      totalSkus: skuCount,
      totalVariants: isVariant ? included.length : null,
      createdAt: createdAt ?? DateTime.now(),
      primaryImage: primary,
    );
  }
}

class ProductCreatedSuccess extends StatelessWidget {
  const ProductCreatedSuccess({
    super.key,
    required this.snapshot,
    required this.onViewProduct,
    required this.onAddAnother,
    required this.onBackToProducts,
  });

  final ProductCreateSuccessSnapshot snapshot;
  final VoidCallback onViewProduct;
  final VoidCallback onAddAnother;
  final VoidCallback onBackToProducts;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
              border: Border.all(color: TenantAdminColors.border),
              boxShadow: TenantAdminShadows.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TenantAdminSpacing.xxl,
                    TenantAdminSpacing.xxl,
                    TenantAdminSpacing.xxl,
                    TenantAdminSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      const _SuccessCheckmark(),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      const Text(
                        'Product Created Successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: TenantAdminColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      const Text(
                        'Your product has been created and is ready to use.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.xl),
                      _ProductSummaryCard(snapshot: snapshot),
                      const SizedBox(height: TenantAdminSpacing.xl),
                      _ActionButtons(
                        canView: snapshot.productId.trim().isNotEmpty,
                        onViewProduct: onViewProduct,
                        onAddAnother: onAddAnother,
                        onBackToProducts: onBackToProducts,
                      ),
                    ],
                  ),
                ),
                _FooterBanner(productName: snapshot.productName),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessCheckmark extends StatelessWidget {
  const _SuccessCheckmark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 6, left: 10, child: _spark(const Color(0xFF22C55E), 7)),
          Positioned(top: 18, right: 8, child: _spark(const Color(0xFFF59E0B), 5)),
          Positioned(bottom: 14, left: 8, child: _spark(const Color(0xFF3B82F6), 6)),
          Positioned(bottom: 8, right: 16, child: _spark(const Color(0xFFEC4899), 5)),
          Positioned(top: 4, right: 28, child: _spark(TenantAdminColors.primary, 4)),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _spark(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({required this.snapshot});

  final ProductCreateSuccessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('MMM d, yyyy h:mm a').format(snapshot.createdAt);
    final facts = <_Fact>[
      _Fact(
        icon: Icons.qr_code_2_outlined,
        label: snapshot.isVariant ? 'Product Code / SKU' : 'SKU',
        value: snapshot.skuOrCodeDisplay,
      ),
      _Fact(
        icon: Icons.circle,
        iconColor: TenantAdminColors.success,
        label: 'Status',
        value: snapshot.statusLabel,
        valueColor: TenantAdminColors.success,
      ),
      _Fact(
        icon: Icons.barcode_reader,
        label: 'Total SKUs',
        value: '${snapshot.totalSkus}',
      ),
      _Fact(
        icon: Icons.dashboard_customize_outlined,
        label: 'Product Type',
        value: snapshot.productTypeLabel,
      ),
      if (snapshot.totalVariants != null)
        _Fact(
          icon: Icons.sell_outlined,
          label: 'Total Variants',
          value: '${snapshot.totalVariants}',
        ),
      _Fact(
        icon: Icons.calendar_today_outlined,
        label: 'Created At',
        value: created,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProductThumb(image: snapshot.primaryImage),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  snapshot.productName.isEmpty
                      ? 'Untitled Product'
                      : snapshot.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 520 ? 3 : 1;
              const gap = TenantAdminSpacing.lg;
              final width = cols == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: TenantAdminSpacing.lg,
                children: [
                  for (final fact in facts)
                    SizedBox(width: width, child: _FactTile(fact: fact)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.image});

  final ProductWizardImageItem? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? const Icon(Icons.inventory_2_outlined,
              color: TenantAdminColors.mutedText)
          : image!.bytes != null
              ? Image.memory(image!.bytes!, fit: BoxFit.cover)
              : (image!.imageUrl.isNotEmpty
                  ? Image.network(image!.imageUrl, fit: BoxFit.cover)
                  : const Icon(Icons.inventory_2_outlined,
                      color: TenantAdminColors.mutedText)),
    );
  }
}

class _Fact {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          fact.icon,
          size: 16,
          color: fact.iconColor ?? TenantAdminColors.mutedText,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fact.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: TenantAdminColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fact.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fact.valueColor ?? TenantAdminColors.bodyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.canView,
    required this.onViewProduct,
    required this.onAddAnother,
    required this.onBackToProducts,
  });

  final bool canView;
  final VoidCallback onViewProduct;
  final VoidCallback onAddAnother;
  final VoidCallback onBackToProducts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560;
        final view = ElevatedButton.icon(
          onPressed: canView ? onViewProduct : null,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('View Product'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TenantAdminColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                TenantAdminColors.primary.withValues(alpha: 0.45),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            elevation: 0,
          ),
        );
        final another = OutlinedButton.icon(
          onPressed: onAddAnother,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Another Product'),
          style: OutlinedButton.styleFrom(
            foregroundColor: TenantAdminColors.primary,
            side: const BorderSide(color: TenantAdminColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
        );
        final back = OutlinedButton.icon(
          onPressed: onBackToProducts,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Products'),
          style: OutlinedButton.styleFrom(
            foregroundColor: TenantAdminColors.bodyText,
            side: const BorderSide(color: TenantAdminColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              view,
              const SizedBox(height: TenantAdminSpacing.sm),
              another,
              const SizedBox(height: TenantAdminSpacing.sm),
              back,
            ],
          );
        }

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: TenantAdminSpacing.sm,
          runSpacing: TenantAdminSpacing.sm,
          children: [view, another, back],
        );
      },
    );
  }
}

class _FooterBanner extends StatelessWidget {
  const _FooterBanner({required this.productName});

  final String productName;

  @override
  Widget build(BuildContext context) {
    final name = productName.trim().isEmpty ? 'Product' : productName.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      color: TenantAdminColors.secondary,
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 16,
            color: TenantAdminColors.primary,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              'Great job! $name has been successfully added to your catalog.',
              style: const TextStyle(
                fontSize: 12,
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
