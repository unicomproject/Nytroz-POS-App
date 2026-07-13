import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashPaymentHeader extends StatefulWidget {
  const CashPaymentHeader({
    super.key,
    required this.onBack,
    required this.showTillStatus,
    required this.tillStatusLabel,
    required this.isTillOpen,
  });

  final VoidCallback onBack;
  final bool showTillStatus;
  final String tillStatusLabel;
  final bool isTillOpen;

  @override
  State<CashPaymentHeader> createState() => _CashPaymentHeaderState();
}

class _CashPaymentHeaderState extends State<CashPaymentHeader> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: widget.onBack,
          tooltip: 'Back to payment methods',
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: TenantAdminColors.surface,
            side: const BorderSide(color: TenantAdminColors.border),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cash Payment',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Accept cash payment from customer',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showTillStatus)
              _TillStatusChip(
                label: widget.tillStatusLabel,
                isOpen: widget.isTillOpen,
              ),
            const SizedBox(width: TenantAdminSpacing.md),
            _DateTimeBlock(now: _now),
          ],
        ),
      ],
    );
  }
}

class _TillStatusChip extends StatelessWidget {
  const _TillStatusChip({
    required this.label,
    required this.isOpen,
  });

  final String label;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final fg = isOpen ? TenantAdminColors.success : TenantAdminColors.danger;
    final bg = isOpen ? const Color(0xFFEFFAF3) : const Color(0xFFFFF1F2);
    final border = isOpen ? const Color(0xFFBBE7C8) : const Color(0xFFFBCACA);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeBlock extends StatelessWidget {
  const _DateTimeBlock({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(now),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            _formatDate(now),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} '
        '${value.day}, ${value.year}';
  }
}
