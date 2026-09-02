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

enum OnlineOrderSummarySemantic {
  newOrder,
  preparing,
  ready,
  delayed,
  collected,
  cancelled,
  collection,
  paymentPaid,
  paymentPending,
  paymentRefunded,
  paymentFailed,
  paymentUnknown,
  items,
}

extension OnlineOrderSummarySemanticColor on OnlineOrderSummarySemantic {
  Color get color => switch (this) {
        OnlineOrderSummarySemantic.newOrder => Colors.blue,
        OnlineOrderSummarySemantic.preparing => Colors.orange,
        OnlineOrderSummarySemantic.ready => Colors.green,
        OnlineOrderSummarySemantic.delayed => Colors.red,
        OnlineOrderSummarySemantic.collected => Colors.purple,
        OnlineOrderSummarySemantic.cancelled => Colors.blueGrey,
        OnlineOrderSummarySemantic.collection => Colors.green,
        OnlineOrderSummarySemantic.paymentPaid => Colors.green,
        OnlineOrderSummarySemantic.paymentPending => Colors.orange,
        OnlineOrderSummarySemantic.paymentRefunded => Colors.blue,
        OnlineOrderSummarySemantic.paymentFailed => Colors.red,
        OnlineOrderSummarySemantic.paymentUnknown => Colors.blueGrey,
        OnlineOrderSummarySemantic.items => Colors.blue,
      };
}

enum OnlineOrderPaymentStatusStyle {
  paid,
  pending,
  refunded,
  failed,
  unknown;

  static OnlineOrderPaymentStatusStyle fromStatus(String status) {
    return switch (status.trim().toUpperCase()) {
      'PAID' => paid,
      'UNPAID' || 'PARTIALLY_PAID' => pending,
      'REFUNDED' || 'PARTIALLY_REFUNDED' => refunded,
      'FAILED' => failed,
      _ => unknown,
    };
  }

  Color get color => switch (this) {
        paid => Colors.green,
        pending => Colors.orange,
        refunded => Colors.blue,
        failed => Colors.red,
        unknown => Colors.blueGrey,
      };

  Color get foreground => switch (this) {
        paid => Colors.green.shade700,
        pending => Colors.orange.shade800,
        refunded => Colors.blue.shade700,
        failed => Colors.red.shade700,
        unknown => Colors.blueGrey.shade700,
      };

  OnlineOrderSummarySemantic get summarySemantic => switch (this) {
        paid => OnlineOrderSummarySemantic.paymentPaid,
        pending => OnlineOrderSummarySemantic.paymentPending,
        refunded => OnlineOrderSummarySemantic.paymentRefunded,
        failed => OnlineOrderSummarySemantic.paymentFailed,
        unknown => OnlineOrderSummarySemantic.paymentUnknown,
      };
}

class OnlineOrderSummaryCard extends StatelessWidget {
  const OnlineOrderSummaryCard({
    required this.title,
    required this.icon,
    required this.semantic,
    this.count,
    this.content,
    this.minHeight,
    super.key,
  }) : assert(count != null || content != null);

  final String title;
  final IconData icon;
  final OnlineOrderSummarySemantic semantic;
  final int? count;
  final Widget? content;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final color = semantic.color;
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .055),
        border: Border.all(color: const Color(0xFFE1E7F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            foregroundColor: color,
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (content case final content?)
                  content
                else
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    final statusStyle = OnlineOrderPaymentStatusStyle.fromStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusStyle.color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusStyle.foreground,
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
