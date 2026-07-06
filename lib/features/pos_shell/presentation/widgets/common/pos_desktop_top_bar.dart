import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosDesktopTopBar extends StatefulWidget {
  const PosDesktopTopBar({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<PosDesktopTopBar> createState() => _PosDesktopTopBarState();
}

class _PosDesktopTopBarState extends State<PosDesktopTopBar> {
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
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border(
          bottom: BorderSide(color: TenantAdminColors.border),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1040;
          final veryCompact = constraints.maxWidth < 760;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  veryCompact ? TenantAdminSpacing.md : TenantAdminSpacing.xl,
            ),
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: veryCompact ? 116 : 156,
                    maxWidth: compact ? 180 : 240,
                  ),
                  child: _TitleBlock(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    showSubtitle: !veryCompact,
                  ),
                ),
                SizedBox(
                  width: veryCompact
                      ? TenantAdminSpacing.sm
                      : TenantAdminSpacing.lg,
                ),
                const Expanded(child: _TopBarSearchField()),
                SizedBox(
                  width: veryCompact
                      ? TenantAdminSpacing.sm
                      : TenantAdminSpacing.lg,
                ),
                const _NotificationButton(),
                if (!veryCompact) ...[
                  const SizedBox(width: TenantAdminSpacing.sm),
                  const _TillStatusChip(),
                ],
                if (!compact) ...[
                  const SizedBox(width: TenantAdminSpacing.md),
                  _DateTimeBlock(now: _now),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.showSubtitle,
  });

  final String title;
  final String subtitle;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ) ??
              const TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}

class _TopBarSearchField extends ConsumerStatefulWidget {
  const _TopBarSearchField();

  @override
  ConsumerState<_TopBarSearchField> createState() => _TopBarSearchFieldState();
}

class _TopBarSearchFieldState extends ConsumerState<_TopBarSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncControllerText(String value) {
    if (_controller.text == value) {
      return;
    }

    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewSaleBrowseRoute =
        GoRouterState.of(context).uri.path == '/pos/new-sale';
    final session = ref.watch(authSessionProvider);
    final canSearchProducts =
        session?.hasPermission(PosPermissionCodes.searchProducts) == true;
    final isSearchEnabled = isNewSaleBrowseRoute && canSearchProducts;
    final searchQuery = isSearchEnabled
        ? ref.watch(posNewSaleSearchQueryProvider)
        : '';
    _syncControllerText(searchQuery);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _controller,
          enabled: isSearchEnabled,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(posNewSaleSearchQueryProvider.notifier).state = value;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: TenantAdminColors.background,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: TenantAdminColors.mutedText,
              size: 22,
            ),
            suffixIcon: isSearchEnabled && searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      ref.read(posNewSaleSearchQueryProvider.notifier).state =
                          '';
                    },
                    tooltip: 'Clear search',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TenantAdminColors.mutedText,
                      size: 20,
                    ),
                  )
                : null,
            hintText: 'Search products, scan barcode or enter SKU',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.md,
              vertical: TenantAdminSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session?.hasPermission(PosPermissionCodes.viewNotifications) != true) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: 'Notifications',
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: TenantAdminColors.background,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: TenantAdminColors.bodyText,
                  size: 23,
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TenantAdminColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TillStatusChip extends ConsumerWidget {
  const _TillStatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session?.hasPermission(PosPermissionCodes.viewTillSession) != true) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: const Color(0xFFBBE7C8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: TenantAdminColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            'Till Open',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TenantAdminColors.success,
                      fontWeight: FontWeight.w800,
                    ) ??
                const TextStyle(
                  color: TenantAdminColors.success,
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
      width: 106,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(now),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ) ??
                const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            _formatDate(now),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}
