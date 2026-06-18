import 'package:flutter/material.dart';

import '../../domain/entities/outlet_details.dart';
import '../config/outlet_details_metric_configs.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';

class OutletDetailsSummaryRow extends StatelessWidget {
  const OutletDetailsSummaryRow({
    super.key,
    required this.outlet,
    required this.metrics,
  });

  final OutletDetails outlet;
  final List<OutletDetailsMetricConfig> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < TenantAdminBreakpoints.mobile
        ? 2
        : width < TenantAdminBreakpoints.tablet
            ? 2
            : metrics.length.clamp(1, 4);
    final cardHeight = width < TenantAdminBreakpoints.mobile ? 156.0 : 168.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: cardHeight,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final config = metrics[index];
        final value = config.valueBuilder(outlet);
        if (value == null) {
          return TenantAdminMetricCard(
            title: config.title,
            value: '—',
            icon: config.icon,
            subtitle: 'Not available',
            dense: true,
          );
        }

        return TenantAdminMetricCard(
          title: config.title,
          value: value,
          icon: config.icon,
          subtitle: config.subtitleBuilder(outlet),
          trend: config.trendBuilder?.call(outlet),
          dense: true,
        );
      },
    );
  }
}
