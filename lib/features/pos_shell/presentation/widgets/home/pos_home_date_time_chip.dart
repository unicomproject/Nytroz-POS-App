import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/timezone_resolver.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosHomeDateTimeChip extends StatefulWidget {
  const PosHomeDateTimeChip({
    super.key,
    required this.serverNowUtc,
    required this.serverTimeReceivedAt,
    required this.outletTimezone,
    required this.fallbackNow,
  });

  final DateTime? serverNowUtc;
  final DateTime? serverTimeReceivedAt;
  final String? outletTimezone;
  final DateTime fallbackNow;

  @override
  State<PosHomeDateTimeChip> createState() => _PosHomeDateTimeChipState();
}

class _PosHomeDateTimeChipState extends State<PosHomeDateTimeChip> {
  Timer? _timer;
  late DateTime _displayNow;

  static const _clockIconSize = 20.0;

  @override
  void initState() {
    super.initState();
    _displayNow = _resolveOutletNow();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        _displayNow = _resolveOutletNow();
      });
    });
  }

  @override
  void didUpdateWidget(covariant PosHomeDateTimeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverNowUtc != widget.serverNowUtc ||
        oldWidget.serverTimeReceivedAt != widget.serverTimeReceivedAt ||
        oldWidget.outletTimezone != widget.outletTimezone) {
      setState(() {
        _displayNow = _resolveOutletNow();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _resolveOutletNow() {
    return TimezoneResolver.resolveOutletNow(
      serverNowUtc: widget.serverNowUtc,
      serverTimeReceivedAt: widget.serverTimeReceivedAt,
      outletTimezone: widget.outletTimezone,
      fallbackNow: widget.fallbackNow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: TenantAdminContentTokens.buttonHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: _clockIconSize,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Flexible(
            child: Text(
              '${_formatTime(_displayNow)}  •  ${_formatDate(_displayNow)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    return DateFormat('h:mm a').format(value);
  }

  String _formatDate(DateTime value) {
    return DateFormat('EEE, MMM d').format(value);
  }
}
