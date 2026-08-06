import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/new_sale/pos_camera_scanner_provider.dart';

class PosNewSaleTopBarContent extends ConsumerStatefulWidget {
  const PosNewSaleTopBarContent({super.key});

  @override
  ConsumerState<PosNewSaleTopBarContent> createState() =>
      _PosNewSaleTopBarContentState();
}

class _PosNewSaleTopBarContentState
    extends ConsumerState<PosNewSaleTopBarContent> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NewSaleSearchField(focusNode: _searchFocusNode),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        const _TerminalOnlineChip(),
      ],
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

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
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
            style: const TextStyle(
              color: Color(0xFF101828),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              prefixIcon: const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFFFF2D1A),
                size: 36,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              hintText: 'Scan barcode or search products',
              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
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
                      color: Color(0xFFFF2D1A),
                      size: 30,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(
                    color: TenantAdminColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(
                    color: TenantAdminColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(
                  color: Color(0xFFFF2D1A),
                  width: 1.5,
                ),
              ),
            ),
            textAlignVertical: TextAlignVertical.center,
            maxLines: 1,
          ),
        ),
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
          color: color,
          width: 1.5,
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
