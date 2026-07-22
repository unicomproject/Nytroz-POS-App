import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/widgets/pos_empty_cart_panel.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../widgets/new_sale/pos_new_sale_action_bar.dart';
import '../widgets/new_sale/pos_barcode_scanner_listener.dart';
import '../widgets/new_sale/pos_product_category_chips.dart';
import '../widgets/new_sale/pos_product_grid.dart';
import '../providers/pos_barcode_scan_controller.dart';
import '../providers/pos_barcode_scan_feedback.dart';
import '../providers/pos_camera_scanner_provider.dart';
import '../widgets/new_sale/pos_camera_barcode_scanner.dart';
import '../../../cart/presentation/providers/pos_new_sale_search_coordinator.dart';

class PosNewSaleScreen extends ConsumerStatefulWidget {
  const PosNewSaleScreen({
    this.onBarcodeCaptured,
    super.key,
  });

  final ValueChanged<String>? onBarcodeCaptured;

  @override
  ConsumerState<PosNewSaleScreen> createState() => _PosNewSaleScreenState();
}

class _PosNewSaleScreenState extends ConsumerState<PosNewSaleScreen> {
  String? _lastRoutePath;
  int _lastFeedbackEventId = 0;
  bool _cameraScannerOpening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routePath = GoRouterState.of(context).uri.path;
    if (routePath == _lastRoutePath) {
      return;
    }

    final enteredNewSale =
        routePath == '/pos/new-sale' && _lastRoutePath != '/pos/new-sale';
    _lastRoutePath = routePath;

    if (enteredNewSale) {
      _resetSearchAfterRouteEntry();
    }
  }

  void _resetSearchAfterRouteEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || GoRouterState.of(context).uri.path != '/pos/new-sale') {
        return;
      }

      ref.read(posNewSaleSearchQueryProvider.notifier).state = '';
      ref.read(posNewSaleSelectedCategoryIdProvider.notifier).state = null;
    });
  }

  Future<void> _openCameraScanner() async {
    if (_cameraScannerOpening ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _cameraScannerOpening = true;
    try {
      final result = ref.read(posCameraScannerSupportedProvider)
          ? await ref.read(posCameraScannerLauncherProvider)(context)
          : const PosCameraScanResult.unsupported();
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final barcode = result.barcode?.trim();
      if (result.type == PosCameraScanResultType.barcode &&
          barcode != null &&
          barcode.isNotEmpty) {
        ref.read(posNewSaleSearchCoordinatorProvider).clearForScanner();
        ref.read(posBarcodeScanControllerProvider.notifier).enqueue(barcode);
        return;
      }
      final message = switch (result.type) {
        PosCameraScanResultType.permissionDenied =>
          'Camera access is disabled. Enable it in system settings.',
        PosCameraScanResultType.unavailable =>
          'No camera is available on this device.',
        PosCameraScanResultType.failed => 'Unable to start the camera scanner.',
        PosCameraScanResultType.unsupported =>
          'Camera scanning is unavailable on this device. Use the connected barcode scanner.',
        _ => null,
      };
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      _cameraScannerOpening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(posBarcodeScanControllerProvider);
    ref.listen(
      posBarcodeScanControllerProvider.select((state) => state.feedbackEvent),
      (_, event) {
        if (event == null || event.id <= _lastFeedbackEventId || !mounted) {
          return;
        }
        _lastFeedbackEventId = event.id;
        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        final feedback = barcodeFeedbackPresentation(event);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(feedback.message),
            backgroundColor: feedback.isSuccess
                ? TenantAdminColors.success
                : TenantAdminColors.danger,
          ));
      },
    );
    ref.listen<int>(posCameraScannerRequestProvider, (_, requestId) {
      if (requestId > 0) {
        _openCameraScanner();
      }
    });
    final scannerEnabled = ModalRoute.of(context)?.isCurrent ?? true;
    return PosBarcodeScannerListener(
      enabled: scannerEnabled,
      onBarcodeScanned: (barcode) {
        ref.read(posNewSaleSearchCoordinatorProvider).clearForScanner();
        widget.onBarcodeCaptured?.call(barcode);
        ref.read(posBarcodeScanControllerProvider.notifier).enqueue(barcode);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSideBySide =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;
          final padding = EdgeInsets.all(
            constraints.maxWidth >= TenantAdminBreakpoints.tablet
                ? TenantAdminSpacing.lg
                : TenantAdminSpacing.md,
          );

          if (!useSideBySide) {
            final cartHeight = constraints.maxHeight < 720 ? 360.0 : 390.0;

            return Padding(
              padding: padding,
              child: Column(
                children: [
                  const Expanded(
                    flex: 6,
                    child: _ProductArea(showActionBar: true),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  SizedBox(
                    height: cartHeight,
                    child: const PosEmptyCartPanel(),
                  ),
                ],
              ),
            );
          }

          final cartWidth = constraints.maxWidth < 1180 ? 330.0 : 360.0;

          return Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: _ProductArea(showActionBar: true),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                SizedBox(
                  width: cartWidth,
                  child: const PosEmptyCartPanel(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductArea extends StatelessWidget {
  const _ProductArea({
    this.showActionBar = false,
  });

  final bool showActionBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PosProductCategoryChips(),
        const SizedBox(height: TenantAdminSpacing.sm),
        const _ProductSectionHeader(),
        const SizedBox(height: TenantAdminSpacing.sm),
        const Expanded(child: PosProductGrid()),
        if (showActionBar) ...[
          const SizedBox(height: TenantAdminSpacing.sm),
          const PosNewSaleActionBar(),
        ],
      ],
    );
  }
}

class _ProductSectionHeader extends ConsumerWidget {
  const _ProductSectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(posNewSaleSearchQueryProvider).trim();
    final selectedCategoryId = ref.watch(posNewSaleSelectedCategoryIdProvider);
    final categoriesAsync = ref.watch(posNewSaleCategoriesProvider);
    final catalogAsync = ref.watch(posNewSaleCatalogProvider);
    final productCount = catalogAsync.maybeWhen(
      data: (catalog) => catalog.products.length,
      orElse: () => 0,
    );
    final selectedCategoryName = categoriesAsync.maybeWhen(
      data: (categories) => categories
          .firstWhere(
            (category) => category.id == selectedCategoryId,
            orElse: () => const PosCatalogCategoryOption(name: 'All'),
          )
          .name,
      orElse: () => 'All',
    );
    final hasSearch = query.isNotEmpty;
    final sectionTitle = hasSearch
        ? 'Search results for "$query"'
        : selectedCategoryId == null
            ? 'All Products ($productCount)'
            : '$selectedCategoryName Products';

    return Row(
      children: [
        Expanded(
          child: Text(
            sectionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w900,
                    ) ??
                const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Text(
          'Sort by: Popular',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ) ??
              const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
