import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/product_local_image_provider.dart';
import '../utils/product_image_url.dart';

class ProductThumbnail extends ConsumerWidget {
  const ProductThumbnail({
    super.key,
    required this.productId,
    this.imageStorageKey,
    this.size = 42,
  });

  final String productId;
  final String? imageStorageKey;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localBytes = ref.watch(productLocalImageCacheProvider)[productId];
    final imageUrl = resolveProductImageUrl(imageStorageKey);

    Widget child;
    if (localBytes != null) {
      child = Image.memory(
        localBytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null) {
      child = Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(size: size),
      );
    } else {
      child = _Placeholder(size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TenantAdminColors.border,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: child,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TenantAdminColors.primary.withValues(alpha: 0.08),
            TenantAdminColors.primary.withValues(alpha: 0.03),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.42,
        color: TenantAdminColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
