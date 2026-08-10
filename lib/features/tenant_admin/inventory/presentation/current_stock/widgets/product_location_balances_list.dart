import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/current_stock_entities.dart';

/// Card showing stock quantities for each outlet/location.
class ProductLocationBalancesTable extends StatelessWidget {
  const ProductLocationBalancesTable({super.key, required this.detail});

  final ProductStockDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.all(TenantAdminSpacing.xl),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 20, color: TenantAdminColors.bodyText),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Balances',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TenantAdminColors.bodyText)),
                    SizedBox(height: 2),
                    Text('Current stock balance by location',
                        style: TextStyle(
                            fontSize: 12, color: TenantAdminColors.mutedText)),
                  ],
                ),
              ],
            ),
          ),
          
          // List of locations
          if (detail.locationBalances.isEmpty)
            const Padding(
              padding: EdgeInsets.all(TenantAdminSpacing.xl),
              child: Center(
                  child: Text('No location data',
                      style:
                          TextStyle(color: TenantAdminColors.mutedText))),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.xl),
              child: Column(
                children: detail.locationBalances.map((loc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                    child: _LocationBalanceRow(loc: loc),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
      ),
    );
  }
}

class _LocationBalanceRow extends StatelessWidget {
  const _LocationBalanceRow({required this.loc});

  final LocationBalance loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // light blue
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined, 
                color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 16),
          // Location Name
          Expanded(
            flex: 2,
            child: Text(
              loc.locationName ?? 'Unknown',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TenantAdminColors.bodyText,
              ),
            ),
          ),
          // Stats
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn('On Hand', loc.onHand.toStringAsFixed(0), const Color(0xFF3B82F6)),
                _StatColumn('Reserved', loc.reserved.toStringAsFixed(0), const Color(0xFFF97316)),
                _StatColumn('Available', loc.available.toStringAsFixed(0), const Color(0xFF22C55E)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: TenantAdminColors.mutedText, size: 20),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: TenantAdminColors.mutedText)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
