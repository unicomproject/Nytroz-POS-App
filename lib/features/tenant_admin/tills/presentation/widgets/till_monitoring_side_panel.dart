import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/till_hardware_readiness.dart';
import '../../domain/entities/till_monitoring.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import 'till_hardware_connection_tile.dart';
import 'till_monitoring_alerts_sheet.dart';

/// Right-hand detail panel for the approved Till Monitoring split view.
class TillMonitoringSidePanel extends ConsumerWidget {
  const TillMonitoringSidePanel({
    super.key,
    required this.tillId,
    this.listItem,
  });

  final String? tillId;

  /// Selected list row used when hardware readiness is unavailable
  /// (for example missing `tenant.hardware.view`).
  final TillMonitoringItem? listItem;

  static const _accent = TenantAdminColors.posHomeAccentOrange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tillId == null || tillId!.isEmpty) {
      return const _PanelShell(
        child: Padding(
          padding: EdgeInsets.all(TenantAdminSpacing.xl),
          child: TenantAdminEmptyState(
            title: 'Select a till',
            message:
                'Choose a till from the list to view cashier, activity and hardware status.',
          ),
        ),
      );
    }

    final canViewHardware = ref.watch(tillHardwareViewAccessProvider);

    if (!canViewHardware) {
      return _PanelShell(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: _buildBasicDetail(
            listItem: listItem,
            hardwareBody: const _HardwarePermissionState(),
          ),
        ),
      );
    }

    final readinessState =
        ref.watch(tillHardwareReadinessFutureProvider(tillId!));
    final detailState = ref.watch(tillDetailProvider(tillId!));

    return _PanelShell(
      child: readinessState.when(
        data: (readiness) {
          if (readiness == null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: _buildBasicDetail(
                listItem: listItem,
                hardwareBody: const TenantAdminEmptyState(
                  title: 'Till details unavailable',
                  message: 'Unable to load hardware readiness for this till.',
                ),
              ),
            );
          }

          final detail = detailState.valueOrNull;
          final allConnections =
              List<TillHardwareConnection>.from(readiness.hardwareConnections);

          // Add static configured hardware if not already in real connections
          if (detail != null) {
            void addStaticHardware(String? name, String type) {
              if (name != null && name.trim().isNotEmpty) {
                // Check if a real connection of this type already exists
                final exists = allConnections
                    .any((c) => c.type.toLowerCase() == type.toLowerCase());
                if (!exists) {
                  allConnections.add(
                    TillHardwareConnection(
                      id: 'static_$type',
                      code: 'STATIC',
                      name: name,
                      type: type,
                      deviceStatus: 'ACTIVE',
                      connectionStatus: TillHardwareConnectionStatus.connected,
                      assignmentSource: 'TILL_CONFIG',
                    ),
                  );
                }
              }
            }

            addStaticHardware(detail.scannerName, 'SCANNER');
            addStaticHardware(detail.printerName, 'PRINTER');
            addStaticHardware(detail.cashDrawerName, 'CASH_DRAWER');
            addStaticHardware(detail.cardReaderName, 'CARD_READER');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailHeader(
                  tillName: readiness.tillName,
                  tillCode: readiness.tillCode,
                  outletName: readiness.outletName,
                  displayStatus: readiness.displayStatus,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                _CashierSection(cashier: readiness.currentCashier),
                const SizedBox(height: TenantAdminSpacing.lg),
                _LastActivitySection(lastActivityAt: readiness.lastActivityAt),
                const SizedBox(height: TenantAdminSpacing.lg),
                _PosDeviceSection(device: readiness.assignedPosDevice),
                const SizedBox(height: TenantAdminSpacing.xl),
                _HardwareSection(
                  connections: allConnections,
                ),
                if (readiness.alertCount > 0) ...[
                  const SizedBox(height: TenantAdminSpacing.xl),
                  _AlertsButton(
                    alertCount: readiness.alertCount,
                    onPressed: () =>
                        TillMonitoringAlertsSheet.show(context, readiness),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(TenantAdminSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) {
          final is404 =
              error is DioException && error.response?.statusCode == 404;

          if (listItem != null && !is404) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: _buildBasicDetail(
                listItem: listItem,
                hardwareBody: _mapError(
                  error: error,
                  onRetry: () => ref
                      .invalidate(tillHardwareReadinessFutureProvider(tillId!)),
                  isHardwareOnly: true,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: _mapError(
              error: error,
              onRetry: () {
                if (listItem == null) {
                  ref.invalidate(tillDetailProvider(tillId!));
                }
                ref.invalidate(tillHardwareReadinessFutureProvider(tillId!));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicDetail({
    required TillMonitoringItem? listItem,
    required Widget hardwareBody,
  }) {
    if (listItem == null) {
      return const TenantAdminEmptyState(
        title: 'Select a till',
        message:
            'Choose a till from the list to view cashier, activity and hardware status.',
      );
    }

    final cashierName = listItem.currentCashierName?.trim();
    final cashier = (cashierName == null || cashierName.isEmpty)
        ? null
        : TillCurrentCashier(
            id: listItem.currentCashierId ?? '',
            displayName: cashierName,
          );
    final posDevice =
        (listItem.assignedPosDeviceName?.trim().isNotEmpty ?? false)
            ? TillAssignedPosDevice(
                id: listItem.assignedPosDeviceId ?? '',
                deviceCode: '',
                deviceName: listItem.assignedPosDeviceName!,
                status: '',
                isTrusted: listItem.isPosDeviceTrusted ?? false,
                lastSeenAt: listItem.lastDeviceSeenAt,
              )
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(
          tillName: listItem.name,
          tillCode: listItem.code,
          outletName: listItem.outletName,
          displayStatus: listItem.displayStatus,
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        _CashierSection(cashier: cashier),
        const SizedBox(height: TenantAdminSpacing.lg),
        _LastActivitySection(
          lastActivityAt:
              listItem.lastSessionActivityAt ?? listItem.lastActiveAt,
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _PosDeviceSection(device: posDevice),
        const SizedBox(height: TenantAdminSpacing.xl),
        hardwareBody,
      ],
    );
  }

  Widget _mapError({
    required Object error,
    required VoidCallback onRetry,
    bool isHardwareOnly = false,
  }) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 403) {
        return const TenantAdminEmptyState(
          title: 'Hardware permission required',
          message: 'You do not have permission to view hardware.',
        );
      }
      if (status == 404) {
        return TenantAdminErrorState(
          title: 'Till unavailable',
          message:
              'This till could not be found. Refresh the list and try again.',
          onRetry: onRetry,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return TenantAdminErrorState(
          title: 'Request timed out',
          message: isHardwareOnly
              ? 'The hardware readiness request timed out.'
              : 'The hardware readiness request timed out.',
          onRetry: onRetry,
        );
      }
      if (error.type == DioExceptionType.connectionError) {
        return TenantAdminErrorState(
          title: 'Network unavailable',
          message: 'Check your connection and try again.',
          onRetry: onRetry,
        );
      }
    }

    if (error is FormatException) {
      return TenantAdminErrorState(
        title: 'Invalid response',
        message: isHardwareOnly
            ? 'The hardware readiness response could not be parsed.'
            : 'The hardware readiness response could not be parsed.',
        onRetry: onRetry,
      );
    }

    return TenantAdminErrorState(
      title: isHardwareOnly
          ? 'Unable to load hardware status'
          : 'Unable to load details',
      message: 'Please try again.',
      onRetry: onRetry,
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: child,
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.tillName,
    required this.tillCode,
    required this.outletName,
    required this.displayStatus,
  });

  final String tillName;
  final String tillCode;
  final String outletName;
  final TillDisplayStatus displayStatus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 360;
        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TenantAdminColors.posHomeAccentOrange
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: TenantAdminColors.posHomeAccentOrange,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tillName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                  if (tillCode.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tillCode,
                      style: const TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: TenantAdminColors.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          outletName.isEmpty ? '-' : outletName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TenantAdminColors.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  icon: const Icon(Icons.close, size: 20, color: TenantAdminColors.mutedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  onPressed: () {
                    ref.read(selectedTillIdProvider.notifier).state = null;
                  },
                );
              },
            ),
          ],
        );

        if (stackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: TenantAdminSpacing.md),
              _OperationalBadge(status: displayStatus),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: TenantAdminSpacing.sm),
            _OperationalBadge(status: displayStatus),
          ],
        );
      },
    );
  }
}

class _OperationalBadge extends StatelessWidget {
  const _OperationalBadge({required this.status});

  final TillDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bg;
    final String text;

    switch (status) {
      case TillDisplayStatus.online:
        color = Colors.green.shade700;
        bg = Colors.green.shade50;
        text = 'ONLINE';
      case TillDisplayStatus.needsAttention:
        color = Colors.orange.shade800;
        bg = Colors.orange.shade50;
        text = 'NEEDS ATTENTION';
      case TillDisplayStatus.offline:
        color = Colors.red.shade700;
        bg = Colors.red.shade50;
        text = 'OFFLINE';
      case TillDisplayStatus.unknown:
        color = Colors.grey.shade700;
        bg = Colors.grey.shade100;
        text = 'UNKNOWN';
    }

    return Semantics(
      label: 'Status $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _CashierSection extends StatelessWidget {
  const _CashierSection({required this.cashier});

  final TillCurrentCashier? cashier;

  @override
  Widget build(BuildContext context) {
    final name = cashier?.displayName.trim();
    final hasCashier = name != null && name.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cashier',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.12),
              child: Text(
                hasCashier ? name[0].toUpperCase() : '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.posHomeAccentOrange,
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Text(
                hasCashier ? name : 'Unassigned',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: hasCashier
                      ? TenantAdminColors.bodyText
                      : TenantAdminColors.mutedText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LastActivitySection extends StatelessWidget {
  const _LastActivitySection({required this.lastActivityAt});

  final DateTime? lastActivityAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last Activity',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          _formatRelative(lastActivityAt),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: lastActivityAt == null
                ? TenantAdminColors.mutedText
                : TenantAdminColors.bodyText,
          ),
        ),
      ],
    );
  }

  static String _formatRelative(DateTime? date) {
    if (date == null) return 'No recent activity';

    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) {
      return DateFormat('h:mm a').format(date.toLocal());
    }
    return DateFormat('MMM d, h:mm a').format(date.toLocal());
  }
}

class _PosDeviceSection extends StatelessWidget {
  const _PosDeviceSection({required this.device});

  final TillAssignedPosDevice? device;

  @override
  Widget build(BuildContext context) {
    final hasDevice = device != null && device!.deviceName.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'POS Device',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (!hasDevice)
          const Text(
            'No POS device assigned',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          )
        else ...[
          Text(
            device!.deviceName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.bodyText,
            ),
          ),
          if (device!.deviceCode.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              device!.deviceCode,
              style: const TextStyle(
                fontSize: 12,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (device!.status.trim().isNotEmpty)
                _DeviceStatusBadge(status: device!.status),
              if (device!.lastSeenAt != null)
                Text(
                  'Last seen ${_formatSeen(device!.lastSeenAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static String _formatSeen(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date.toLocal());
  }
}

class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final isActive = normalized == 'ACTIVE' || normalized == 'ONLINE';
    final color =
        isActive ? TenantAdminColors.success : TenantAdminColors.mutedText;
    final bg = isActive ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        normalized.isEmpty ? 'UNKNOWN' : normalized,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _HardwareSection extends StatelessWidget {
  const _HardwareSection({
    required this.connections,
  });

  final List<TillHardwareConnection> connections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hardware Connections',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        if (connections.isEmpty)
          const Text(
            'No hardware connections found.',
            style: TextStyle(color: TenantAdminColors.mutedText),
          )
        else
          ...connections.map(
            (connection) => Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
              child: TillHardwareConnectionTile(connection: connection),
            ),
          ),
      ],
    );
  }
}

class _HardwarePermissionState extends StatelessWidget {
  const _HardwarePermissionState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hardware Connections',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.mutedText,
            ),
          ),
          SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'You do not have permission to view hardware.',
            style: TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsButton extends StatelessWidget {
  const _AlertsButton({
    required this.alertCount,
    required this.onPressed,
  });

  final int alertCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: TenantAdminColors.danger,
        ),
        label: Text(
          'View Alerts ($alertCount)',
          style: const TextStyle(
            color: TenantAdminColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: TillMonitoringSidePanel._accent),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
        ),
      ),
    );
  }
}
