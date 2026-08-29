import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class OnlineOrderUi {
  static const desktopBreakpoint = 1200.0;
  static const tabletLandscapeBreakpoint = 1024.0;
  static const phoneBreakpoint = 768.0;
  static const smallPhoneBreakpoint = 420.0;

  static const accent = Color(0xFFFF6A00);
  static const accentSoft = Color(0xFFFFEFE5);
  static const canvas = Color(0xFFF7F9FC);
  static const ink = Color(0xFF0B2147);
  static const muted = Color(0xFF718096);

  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: ink,
  );
  static const subtitle = TextStyle(fontSize: 13, color: muted);

  static String money(String currency, double value) =>
      '$currency ${NumberFormat('#,##0.00').format(value)}';

  static String collection(DateTime? value) => value == null
      ? 'Not scheduled'
      : DateFormat('dd MMM, hh:mm a').format(value.toLocal());
}

class OnlineOrderStatusChip extends StatelessWidget {
  const OnlineOrderStatusChip({
    required this.label,
    required this.status,
    super.key,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'READY' || 'READY_FOR_COLLECTION' || 'COMPLETED' => Colors.green,
      'PREPARING' || 'PICKING' || 'PICKED' || 'PACKED' => Colors.blue,
      'CANCELLED' => Colors.red,
      _ => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status.toUpperCase().contains('PAID');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (paid ? Colors.green : Colors.orange).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: paid ? Colors.green.shade700 : Colors.orange.shade800,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CollectionUrgencyIndicator extends StatelessWidget {
  const CollectionUrgencyIndicator({required this.collectionAt, super.key});

  final DateTime? collectionAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: OnlineOrderUi.muted,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            OnlineOrderUi.collection(collectionAt),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: OnlineOrderUi.muted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class OnlineOrderScreenState extends StatelessWidget {
  const OnlineOrderScreenState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    super.key,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: Colors.blueGrey),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
}
