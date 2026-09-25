import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../sale/presentation/widgets/new_sale/pos_barcode_scanner_listener.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_online_order_collection_provider.dart';
import '../utils/click_collect_qr.dart';
import '../widgets/collection/collection_scan_widgets.dart';
import '../widgets/online_order_ui.dart';

class CollectionQrScanScreen extends ConsumerStatefulWidget {
  const CollectionQrScanScreen({super.key});

  @override
  ConsumerState<CollectionQrScanScreen> createState() =>
      _CollectionQrScanScreenState();
}

class _CollectionQrScanScreenState extends ConsumerState<CollectionQrScanScreen>
    with WidgetsBindingObserver {
  final _focusNode = FocusNode();
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(posOnlineOrderCollectionProvider.notifier).resetToScanner();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) setState(() => _resumed = state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onScan(String value) async {
    if (!_resumed || ModalRoute.of(context)?.isCurrent != true) return;
    await _validateAndRoute(value);
  }

  Future<void> _validateAndRoute(String token) async {
    // The customer's QR encodes `CLICK_COLLECT:{tenantId}:{orderId}:{code}`;
    // only the opaque code is a valid collection credential. Manual entry
    // (or a scan of just the code) falls back to the raw value unchanged.
    final code = ClickCollectQrPayload.tryParse(token)?.code ?? token.trim();
    final controller = ref.read(posOnlineOrderCollectionProvider.notifier);
    await controller.validateToken(code);
    if (!mounted) return;
    final state = ref.read(posOnlineOrderCollectionProvider);
    switch (state.phase) {
      case PosCollectionPhase.validReady:
      case PosCollectionPhase.paymentRequired:
        context.go('/pos/online-orders/collection/verification');
      case PosCollectionPhase.invalidQr:
      case PosCollectionPhase.invalidExpired:
      case PosCollectionPhase.invalidWrongOutlet:
      case PosCollectionPhase.invalidNotReady:
      case PosCollectionPhase.invalidCancelled:
      case PosCollectionPhase.invalidAlreadyCollected:
      case PosCollectionPhase.invalidOther:
        context.go('/pos/online-orders/collection/rejected');
      default:
        break;
    }
  }

  Future<void> _openManualEntry() async {
    final permissions =
        ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canManualCollectionLookup(permissions) &&
        !PosPermissionAccess.canValidateCollectionQr(permissions)) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'Manual collection lookup is not available for this account.',
      );
      return;
    }

    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ManualCollectionCodeSheet(),
    );
    if (token == null || token.isEmpty || !mounted) return;
    await _validateAndRoute(token);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final permissions =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canScanCollectionQr(permissions)) {
      return const TenantAdminForbiddenScreen();
    }

    final state = ref.watch(posOnlineOrderCollectionProvider);
    final validating = state.isValidating;

    return PosBarcodeScannerListener(
      enabled: _resumed &&
          !validating &&
          (ModalRoute.of(context)?.isCurrent ?? true),
      onBarcodeScanned: _onScan,
      child: ColoredBox(
        color: OnlineOrderUi.canvas,
        child: Focus(
          focusNode: _focusNode,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;
              final mainColumn = SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go('/pos/online-orders'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Online Orders'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Scan Customer Collection QR',
                            style: OnlineOrderUi.title,
                          ),
                        ),
                        Chip(
                          label: const Text('Step 1 of 4'),
                          backgroundColor: scheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask the customer to show their collection QR, then scan it with the HID scanner.',
                      style: OnlineOrderUi.subtitle,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TenantAdminColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: TenantAdminColors.info),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Each collection QR is unique and single-use for secure handover.',
                              style: TextStyle(color: TenantAdminColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CollectionScannerPanel(
                      isValidating: validating,
                      onTapFocus: () => _focusNode.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR',
                              style: OnlineOrderUi.subtitle
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('collection-manual-entry'),
                      onPressed: validating ? null : _openManualEntry,
                      icon: const Icon(Icons.keyboard_alt_outlined),
                      label: const Text('Enter Order Number Manually'),
                    ),
                    if (!wide) ...[
                      const SizedBox(height: 20),
                      const CollectionSidebarCards(),
                    ],
                  ],
                ),
              );

              if (!wide) return mainColumn;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: mainColumn),
                  const Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(0, 16, 20, 20),
                      child: CollectionSidebarCards(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ManualCollectionCodeSheet extends StatefulWidget {
  const _ManualCollectionCodeSheet();

  @override
  State<_ManualCollectionCodeSheet> createState() =>
      _ManualCollectionCodeSheetState();
}

class _ManualCollectionCodeSheetState
    extends State<_ManualCollectionCodeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter collection code manually',
              style: OnlineOrderUi.title,
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste or type the opaque collection QR token / code.',
              style: OnlineOrderUi.subtitle,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('collection-manual-code-field'),
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Collection code',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('collection-manual-validate'),
              onPressed: _submit,
              child: const Text('Validate'),
            ),
          ],
        ),
      );
}
