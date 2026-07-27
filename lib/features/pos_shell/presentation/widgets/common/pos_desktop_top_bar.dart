import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_camera_scanner_provider.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosDesktopTopBar extends StatefulWidget {
  const PosDesktopTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.showSearch = true,
    this.isNewSale = false,
  });

  final String title;
  final String subtitle;
  final bool showSearch;
  final bool isNewSale;

  @override
  State<PosDesktopTopBar> createState() => _PosDesktopTopBarState();
}

class _PosDesktopTopBarState extends State<PosDesktopTopBar> {
  late DateTime _now;
  final FocusNode _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewSale = widget.isNewSale;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isNewSale
            ? TenantAdminColors.posHomeDarkBackground
            : TenantAdminColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isNewSale
                ? TenantAdminColors.posHomeDarkBorder
                : TenantAdminColors.border,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1040;
          final veryCompact = constraints.maxWidth < 760;
          final showScanner = widget.showSearch && isNewSale;

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
                  child: showScanner
                      ? const _NewSaleBrand()
                      : _TitleBlock(
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
                if (widget.showSearch) ...[
                  Expanded(
                    child: showScanner
                        ? _NewSaleSearchField(focusNode: _searchFocusNode)
                        : _TopBarSearchField(
                            focusNode: _searchFocusNode,
                            isNewSaleBrowseRoute: isNewSale,
                          ),
                  ),
                  SizedBox(
                    width: veryCompact
                        ? TenantAdminSpacing.sm
                        : TenantAdminSpacing.lg,
                  ),
                ] else
                  const Spacer(),
                _NotificationButton(dark: showScanner),
                if (!veryCompact) ...[
                  const SizedBox(width: TenantAdminSpacing.sm),
                  if (showScanner)
                    const _TerminalOnlineChip()
                  else
                    const _TillStatusChip(),
                ],
                if (!compact && !showScanner) ...[
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

class _NewSaleBrand extends StatelessWidget {
  const _NewSaleBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TenantAdminColors.surface,
                    fontWeight: FontWeight.w800,
                  ),
              children: const [
                TextSpan(text: 'OneVerz '),
                TextSpan(
                  text: 'POS',
                  style: TextStyle(
                    color: TenantAdminColors.posNewSaleAccentEnd,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
  const _TopBarSearchField({
    required this.focusNode,
    required this.isNewSaleBrowseRoute,
  });

  final FocusNode focusNode;
  final bool isNewSaleBrowseRoute;

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
    final session = ref.watch(authSessionProvider);
    final canSearchProducts =
        session?.hasPermission(PosPermissionCodes.searchProducts) == true;
    final isSearchEnabled = widget.isNewSaleBrowseRoute && canSearchProducts;
    final searchQuery =
        isSearchEnabled ? ref.watch(posNewSaleSearchQueryProvider) : '';
    _syncControllerText(searchQuery);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _controller,
          focusNode: widget.focusNode,
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

class _NewSaleSearchField extends ConsumerStatefulWidget {
  const _NewSaleSearchField({required this.focusNode});

  final FocusNode focusNode;

  @override
  ConsumerState<_NewSaleSearchField> createState() =>
      _NewSaleSearchFieldState();
}

class _NewSaleSearchFieldState extends ConsumerState<_NewSaleSearchField> {
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final canSearch =
        session?.hasPermission(PosPermissionCodes.searchProducts) == true;
    final query = canSearch ? ref.watch(posNewSaleSearchQueryProvider) : '';
    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: SizedBox(
        height: 58,
        child: TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          enabled: canSearch,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(posNewSaleSearchQueryProvider.notifier).state = value;
          },
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: TenantAdminColors.posNewSaleSearchText,
                fontWeight: FontWeight.w800,
              ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TenantAdminColors.surface,
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: TenantAdminColors.posNewSaleAccent,
                size: 34,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 58),
            hint: const Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan barcode or search products',
                  style: TextStyle(
                    color: TenantAdminColors.posNewSaleSearchText,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Use scanner or type product name',
                  style: TextStyle(
                    color: TenantAdminColors.posNewSaleSearchHint,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (query.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      ref.read(posNewSaleSearchQueryProvider.notifier).state =
                          '';
                    },
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  key: const Key('new-sale-scanner-button'),
                  onPressed: canSearch
                      ? () {
                          final current =
                              ref.read(posCameraScannerRequestProvider);
                          ref
                              .read(posCameraScannerRequestProvider.notifier)
                              .state = current + 1;
                        }
                      : null,
                  tooltip: 'Open barcode scanner',
                  icon: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: TenantAdminColors.posNewSaleAccent,
                    size: 27,
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.xs),
              ],
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(
                color: TenantAdminColors.posNewSaleAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton({this.dark = false});

  final bool dark;

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
          color: dark
              ? TenantAdminColors.posHomeDarkSurface
              : TenantAdminColors.background,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: Icon(
              Icons.notifications_none_rounded,
              color:
                  dark ? TenantAdminColors.surface : TenantAdminColors.bodyText,
              size: 23,
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
    final tillState = ref.watch(tillProvider);
    final isOpen = tillState.hasOpenSession;
    final statusLabel = isOpen ? 'Till Open' : 'Till Closed';
    final statusColor =
        isOpen ? TenantAdminColors.success : TenantAdminColors.mutedText;
    final statusBackground =
        isOpen ? const Color(0xFFEFFAF3) : const Color(0xFFF3F4F6);
    final statusBorder =
        isOpen ? const Color(0xFFBBE7C8) : const Color(0xFFD1D5DB);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: statusBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ) ??
                TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _TerminalOnlineChip extends ConsumerWidget {
  const _TerminalOnlineChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceActivationProvider).deviceContext;
    final connected =
        device != null && device.isTrusted && device.deviceId.trim().isNotEmpty;
    final color = connected
        ? TenantAdminColors.posNewSaleOnline
        : TenantAdminColors.offline;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.posHomeDarkBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: connected
              ? TenantAdminColors.posNewSaleOnlineBorder
              : TenantAdminColors.posHomeDarkBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            connected ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
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
