import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_online_order_collection_provider.dart';
import '../widgets/collection/collection_verification_widgets.dart';
import '../widgets/online_order_ui.dart';

class CollectionHandoverScreen extends ConsumerStatefulWidget {
  const CollectionHandoverScreen({super.key});

  @override
  ConsumerState<CollectionHandoverScreen> createState() =>
      _CollectionHandoverScreenState();
}

class _CollectionHandoverScreenState
    extends ConsumerState<CollectionHandoverScreen> {
  final _checked =
      List<bool>.filled(CollectionHandoverChecklist.labels.length, false);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final permissions =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canHandoverCollection(permissions)) {
      return const TenantAdminForbiddenScreen();
    }

    final state = ref.watch(posOnlineOrderCollectionProvider);
    final validation = state.validation;
    if (validation == null) {
      return ColoredBox(
        color: OnlineOrderUi.canvas,
        child: Center(
          child: FilledButton(
            onPressed: () => context.go('/pos/online-orders/collection/scan'),
            child: const Text('Start collection scan'),
          ),
        ),
      );
    }

    final checklist = CollectionHandoverChecklist(
      checked: _checked,
      onChanged: (index) {
        setState(() => _checked[index] = !_checked[index]);
      },
    );

    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  context.go('/pos/online-orders/collection/verification'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Verification'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text('Handover & Collect', style: OnlineOrderUi.title),
              ),
              Chip(
                label: const Text('Step 3 of 4'),
                backgroundColor: scheme.primaryContainer,
                labelStyle: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order ${validation.orderNumber}',
            style: OnlineOrderUi.subtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: OnlineOrderUi.ink,
            ),
          ),
          const SizedBox(height: 16),
          checklist,
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: TenantAdminColors.danger),
            ),
          ],
          const SizedBox(height: 20),
          PosPrimaryActionButton(
            key: const Key('collection-mark-collected'),
            label: 'Confirm Handover & Mark as Collected',
            leadingIcon: Icons.check_circle_outline,
            fullWidth: true,
            isLoading: state.isSubmittingHandover,
            onPressed: checklist.allChecked && !state.isSubmittingHandover
                ? () async {
                    final ok = await ref
                        .read(posOnlineOrderCollectionProvider.notifier)
                        .completeHandover();
                    if (!context.mounted) return;
                    if (ok) {
                      context.go('/pos/online-orders/collection/complete');
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
