import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class DashboardActionGrid extends StatelessWidget {
  const DashboardActionGrid({
    super.key,
    required this.cards,
    required this.compact,
  });

  final List<Widget> cards;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 520 ? 1 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: TenantAdminSpacing.md,
            mainAxisSpacing: TenantAdminSpacing.md,
            childAspectRatio: columns == 1 ? 1.72 : 1.38,
            children: cards,
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxHeight - TenantAdminSpacing.md) / 2;
        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: TenantAdminSpacing.md,
            mainAxisSpacing: TenantAdminSpacing.md,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}
