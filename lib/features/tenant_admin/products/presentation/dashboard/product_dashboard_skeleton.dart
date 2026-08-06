import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductDashboardSkeleton extends StatelessWidget {
  const ProductDashboardSkeleton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = compact ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: _SkeletonBox(height: 42)),
            SizedBox(width: TenantAdminSpacing.sm),
            Expanded(child: _SkeletonBox(height: 42)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: TenantAdminSpacing.lg,
            mainAxisSpacing: TenantAdminSpacing.lg,
            mainAxisExtent: compact ? 172 : 168,
          ),
          itemCount: compact ? 4 : 6,
          itemBuilder: (context, index) =>
              _SkeletonBox(height: compact ? 172 : 168),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;

            if (isNarrow) {
              return const Column(
                children: [
                  _SkeletonBox(height: 280),
                  SizedBox(height: TenantAdminSpacing.lg),
                  _SkeletonBox(height: 280),
                ],
              );
            }

            return const Row(
              children: [
                Expanded(child: _SkeletonBox(height: 280)),
                SizedBox(width: TenantAdminSpacing.lg),
                Expanded(child: _SkeletonBox(height: 280)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 88,
            height: 10,
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 18,
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
