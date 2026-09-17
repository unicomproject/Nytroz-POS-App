import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_online_order_collection_provider.dart';
import '../widgets/online_order_ui.dart';

class CollectionQrRejectedScreen extends ConsumerWidget {
  const CollectionQrRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posOnlineOrderCollectionProvider);
    final message = state.errorMessage ??
        state.failureReason?.safeMessage ??
        'Unable to validate this collection QR.';

    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 56,
                    color: TenantAdminColors.danger,
                  ),
                  const SizedBox(height: 16),
                  const Text('Collection QR rejected',
                      style: OnlineOrderUi.title),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: OnlineOrderUi.subtitle,
                  ),
                  const SizedBox(height: 24),
                  PosPrimaryActionButton(
                    key: const Key('collection-rescan'),
                    label: 'Rescan',
                    leadingIcon: Icons.refresh,
                    fullWidth: true,
                    onPressed: () {
                      ref
                          .read(posOnlineOrderCollectionProvider.notifier)
                          .resetToScanner();
                      context.go('/pos/online-orders/collection/scan');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
