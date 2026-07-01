import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_customer.dart';
import '../providers/customer_search_provider.dart';
import 'customer_search_empty_state.dart';
import 'customer_search_field.dart';
import 'quick_add_customer_form.dart';
import 'recent_customer_tile.dart';

/// Opens the New Sale "Add Customer" modal.
///
/// Tablet/desktop: centered, width-constrained dialog. Mobile: full-screen
/// dialog so the search, rows and form stay touch-friendly. Frontend only —
/// selecting/creating a customer updates local UI state and never calls
/// checkout/backend.
Future<void> showAddCustomerDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const AddCustomerDialog(),
  );
}

/// Which view the modal is showing.
enum _AddCustomerView { search, addNew }

class AddCustomerDialog extends StatelessWidget {
  const AddCustomerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < TenantAdminBreakpoints.mobile;

    if (isMobile) {
      return const Dialog.fullscreen(
        backgroundColor: TenantAdminColors.surface,
        child: _AddCustomerContent(isFullScreen: true),
      );
    }

    return Dialog(
      backgroundColor: TenantAdminColors.surface,
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.85,
        ),
        child: const _AddCustomerContent(isFullScreen: false),
      ),
    );
  }
}

class _AddCustomerContent extends ConsumerStatefulWidget {
  const _AddCustomerContent({required this.isFullScreen});

  final bool isFullScreen;

  @override
  ConsumerState<_AddCustomerContent> createState() =>
      _AddCustomerContentState();
}

class _AddCustomerContentState extends ConsumerState<_AddCustomerContent> {
  _AddCustomerView _view = _AddCustomerView.search;

  void _showSearch() => setState(() => _view = _AddCustomerView.search);
  void _showAddNew() {
    if (!_canCreate) {
      return;
    }
    setState(() => _view = _AddCustomerView.addNew);
  }

  /// Quick Add (create customer) requires the create permission. Search/select
  /// only needs the view permission, which the modal entry point already gates.
  bool get _canCreate {
    final session = ref.watch(authSessionProvider);
    if (session == null) {
      return false;
    }
    return PosPermissionAccess.hasAny(
      session.permissionCodes.toSet(),
      PosPermissionAccess.customerCreateAccessCodes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAddNew = _view == _AddCustomerView.addNew;

    final content = Column(
      mainAxisSize: widget.isFullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _DialogHeader(
          onClose: () => Navigator.of(context).maybePop(),
          onBack: isAddNew ? _showSearch : null,
        ),
        const Divider(height: 1, color: TenantAdminColors.border),
        Flexible(
          child: isAddNew ? _buildAddNew(context) : _buildSearch(context),
        ),
        if (!isAddNew) const _FooterInfoBar(),
      ],
    );

    if (widget.isFullScreen) {
      return SafeArea(child: content);
    }

    return content;
  }

  Widget _buildSearch(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TenantAdminSpacing.lg,
            TenantAdminSpacing.lg,
            TenantAdminSpacing.lg,
            TenantAdminSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomerSearchField(),
              if (_canCreate) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                _AddNewCustomerButton(onPressed: _showAddNew),
              ],
              const SizedBox(height: TenantAdminSpacing.lg),
              _RecentCustomersHeader(
                onViewAll: () => _showSnack(
                  'All customers screen is not available yet.',
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: _RecentCustomersList(
            onSelect: _selectCustomer,
            onAddNew: _canCreate ? _showAddNew : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAddNew(BuildContext context) {
    return QuickAddCustomerForm(onAttached: _onCustomerAttached);
  }

  void _selectCustomer(PosCustomer customer) {
    ref.read(selectedCustomerProvider.notifier).state = customer;
    Navigator.of(context).maybePop();
    _showSnack('Customer attached: ${customer.name}');
  }

  void _onCustomerAttached(PosCustomer customer) {
    // The registration controller already set the selection + local list.
    Navigator.of(context).maybePop();
    _showSnack('Customer attached: ${customer.name}');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose, this.onBack});

  final VoidCallback onClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.sm,
        TenantAdminSpacing.md,
        TenantAdminSpacing.sm,
        TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              color: TenantAdminColors.bodyText,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: TenantAdminSpacing.sm),
              child: Icon(
                Icons.person_add_alt_1_outlined,
                color: TenantAdminColors.info,
              ),
            ),
          const SizedBox(width: TenantAdminSpacing.xs),
          Expanded(
            child: Text(
              'Add Customer',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            color: TenantAdminColors.mutedText,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }
}

class _AddNewCustomerButton extends StatelessWidget {
  const _AddNewCustomerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Add New Customer'),
        style: OutlinedButton.styleFrom(
          foregroundColor: TenantAdminColors.info,
          side: const BorderSide(color: TenantAdminColors.info),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
        ),
      ),
    );
  }
}

class _RecentCustomersHeader extends StatelessWidget {
  const _RecentCustomersHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Recent Customers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.sm,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: TenantAdminColors.info,
          ),
          child: const Text('View All'),
        ),
      ],
    );
  }
}

class _RecentCustomersList extends ConsumerWidget {
  const _RecentCustomersList({required this.onSelect, this.onAddNew});

  final ValueChanged<PosCustomer> onSelect;
  final VoidCallback? onAddNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerSearchResultsProvider);

    return customersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(TenantAdminSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SingleChildScrollView(
        child: _CustomerListError(
          onRetry: () => ref.invalidate(customerSearchResultsProvider),
        ),
      ),
      data: (customers) {
        if (customers.isEmpty) {
          return SingleChildScrollView(
            child: CustomerSearchEmptyState(onAddNew: onAddNew),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            TenantAdminSpacing.md,
            0,
            TenantAdminSpacing.md,
            TenantAdminSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
          ),
          itemCount: customers.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: TenantAdminColors.border,
          ),
          itemBuilder: (context, index) {
            final customer = customers[index];
            return RecentCustomerTile(
              customer: customer,
              onTap: () => onSelect(customer),
            );
          },
        );
      },
    );
  }
}

class _CustomerListError extends StatelessWidget {
  const _CustomerListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 28,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            "Couldn't load customers",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: TenantAdminColors.info,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterInfoBar extends StatelessWidget {
  const _FooterInfoBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: TenantAdminColors.background,
        border: Border(
          top: BorderSide(color: TenantAdminColors.border),
        ),
      ),
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              'Customers help you track sales and earn loyalty points.',
              style: TenantAdminTextStyles.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
