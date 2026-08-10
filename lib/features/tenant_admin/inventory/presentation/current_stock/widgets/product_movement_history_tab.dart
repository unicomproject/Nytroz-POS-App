import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/current_stock_entities.dart';
import '../providers/current_stock_providers.dart';

/// Card showing the 5 most recent stock movements for a given variant.
class RecentMovementsTable extends ConsumerWidget {
  const RecentMovementsTable({super.key, required this.variantId});

  final String variantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(stockMovementHistoryProvider(variantId));

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
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.history,
                        size: 20, color: TenantAdminColors.bodyText),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Movements',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: TenantAdminColors.bodyText)),
                        SizedBox(height: 2),
                        Text('Latest stock movements for this product',
                            style: TextStyle(
                                fontSize: 12, color: TenantAdminColors.mutedText)),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3B82F6), // blue
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          
          historyState.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(TenantAdminSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              child: Center(
                  child: Text('Error: ${err.toString()}',
                      style: const TextStyle(
                          color: TenantAdminColors.danger))),
            ),
            data: (pageData) {
              if (pageData.items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(TenantAdminSpacing.xl),
                  child: Center(
                      child: Text('No movements recorded.',
                          style: TextStyle(
                              color: TenantAdminColors.mutedText))),
                );
              }
              // Show only the 5 most recent items
              final recent = pageData.items.take(5).toList();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.xl),
                child: Column(
                  children: recent.map((move) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                      child: MovementRow(move: move),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
      ),
    );
  }
}

class MovementRow extends StatelessWidget {
  const MovementRow({super.key, required this.move});

  final StockMovementHistory move;

  static IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'opening balance':
        return Icons.arrow_upward;
      case 'adjustment out':
      case 'adjustmentout':
        return Icons.arrow_downward;
      case 'sale out':
      case 'saleout':
        return Icons.shopping_cart_outlined;
      case 'return in':
      case 'returnin':
        return Icons.keyboard_return;
      default:
        return Icons.swap_horiz;
    }
  }

  static Color _colorForChange(double change) {
    if (change > 0) return const Color(0xFF22C55E); // Green
    if (change < 0) return const Color(0xFFEF4444); // Red
    return TenantAdminColors.mutedText;
  }
  
  static Color _bgForChange(double change) {
    if (change > 0) return const Color(0xFFDCFCE7); // Light Green
    if (change < 0) return const Color(0xFFFEE2E2); // Light Red
    return const Color(0xFFF1F5F9); // Light Gray
  }

  @override
  Widget build(BuildContext context) {
    final changeColor = _colorForChange(move.change);
    
    // For icon background, we use specific colors based on type to match mockup
    Color iconColor = changeColor;
    Color iconBg = _bgForChange(move.change);
    
    if (move.movementType?.toLowerCase() == 'adjustment out') {
       iconColor = const Color(0xFFF97316);
       iconBg = const Color(0xFFFFF7ED);
    }

    final date = move.date;
    String dateStr = '';
    String timeStr = '';
    if (date != null) {
      final local = date.toLocal();
      dateStr = '${_monthName(local.month)} ${local.day}, ${local.year}';
      final h = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final m = local.minute.toString().padLeft(2, '0');
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      timeStr = '$h:$m $ampm';
    }

    final sign = move.change > 0 ? '+' : '';

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
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconForType(move.movementType), color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.movementType ?? 'Movement',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.bodyText),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${move.reference ?? 'Manual'} • ${move.locationName ?? 'Unknown'}',
                  style: const TextStyle(
                      fontSize: 12, color: TenantAdminColors.mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Date & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                    fontSize: 12, color: TenantAdminColors.mutedText),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: const TextStyle(
                    fontSize: 11, color: TenantAdminColors.mutedText),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Quantity Change
          SizedBox(
            width: 40,
            child: Text(
              '$sign${move.change.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: changeColor),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: TenantAdminColors.mutedText, size: 20),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }
}
