import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../pos/presentation/widgets/new_sale/navigation/pos_cashier_bottom_navigation.dart';
import '../../../pos_shell/presentation/widgets/common/pos_top_bar.dart';
import '../../../pos_shell/presentation/widgets/common/pos_top_bar_notification_button.dart';
import '../../../pos_shell/presentation/widgets/home/pos_dashboard_top_bar_content.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_customer.dart';
import '../providers/checkout_customer_provider.dart';
import '../widgets/payment_method/payment_method_style.dart';

class PosCheckoutCustomerScreen extends ConsumerStatefulWidget {
  const PosCheckoutCustomerScreen({super.key, this.showChrome = true});

  final bool showChrome;

  @override
  ConsumerState<PosCheckoutCustomerScreen> createState() =>
      _PosCheckoutCustomerScreenState();
}

class _PosCheckoutCustomerScreenState
    extends ConsumerState<PosCheckoutCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final permissions =
          ref.read(authSessionProvider)?.permissionCodes.toSet() ??
              const <String>{};
      if (PosPermissionAccess.canViewCustomers(permissions)) {
        ref.read(checkoutCustomerProvider.notifier).search('');
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutCustomerProvider);
    final cart = ref.watch(posNewSaleCartProvider);
    final permissions =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ??
            const <String>{};
    final canView = PosPermissionAccess.canViewCustomers(permissions);
    final canCreate = PosPermissionAccess.canCreateCustomer(permissions);

    return ColoredBox(
      key: const ValueKey('checkout-customer-screen'),
      color: PaymentMethodStyle.background,
      child: Column(
        children: [
          if (widget.showChrome)
            const PosTopBar(
              content: PosDashboardTopBarContent(),
              trailing: PosTopBarNotificationButton(dark: true),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final body = wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _CustomerSearchPanel(
                              state: state,
                              selected: cart.selectedCustomer,
                              controller: _searchController,
                              canView: canView,
                              onChanged: _onSearchChanged,
                              onSubmitted: _searchNow,
                              onRetry: () => _searchNow(_searchController.text),
                              onLoadMore: ref
                                  .read(checkoutCustomerProvider.notifier)
                                  .loadMore,
                              onSelect: _selectCustomer,
                              onWalkIn: cart.selectedCustomer == null
                                  ? null
                                  : () => _selectCustomer(null),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CreateCustomerPanel(
                              formKey: _formKey,
                              nameController: _nameController,
                              phoneController: _phoneController,
                              emailController: _emailController,
                              canCreate: canCreate,
                              state: state,
                              onSubmit: _createCustomer,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 540,
                              child: _CustomerSearchPanel(
                                state: state,
                                selected: cart.selectedCustomer,
                                controller: _searchController,
                                canView: canView,
                                onChanged: _onSearchChanged,
                                onSubmitted: _searchNow,
                                onRetry: () =>
                                    _searchNow(_searchController.text),
                                onLoadMore: ref
                                    .read(checkoutCustomerProvider.notifier)
                                    .loadMore,
                                onSelect: _selectCustomer,
                                onWalkIn: cart.selectedCustomer == null
                                    ? null
                                    : () => _selectCustomer(null),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 560,
                              child: _CreateCustomerPanel(
                                formKey: _formKey,
                                nameController: _nameController,
                                phoneController: _phoneController,
                                emailController: _emailController,
                                canCreate: canCreate,
                                state: state,
                                onSubmit: _createCustomer,
                              ),
                            ),
                          ],
                        ),
                      );
                return Padding(
                  padding: TenantAdminInsets.pageForWidth(
                    constraints.maxWidth,
                  ),
                  child: DecoratedBox(
                    key: const ValueKey('checkout-customer-workspace'),
                    decoration: BoxDecoration(
                      color: TenantAdminColors.surface,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                      border: Border.all(color: TenantAdminColors.border),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        constraints.maxWidth < 700
                            ? TenantAdminSpacing.md
                            : TenantAdminSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ScreenHeader(onBack: context.pop),
                          const SizedBox(height: TenantAdminSpacing.lg),
                          Expanded(child: body),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.showChrome) const PosCashierBottomNavigation(),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _searchNow(value));
  }

  void _searchNow(String value) {
    _debounce?.cancel();
    ref.read(checkoutCustomerProvider.notifier).search(value);
  }

  Future<void> _selectCustomer(PosCustomer? customer) async {
    final success = await ref
        .read(checkoutCustomerProvider.notifier)
        .applyCustomer(customer);
    if (success && mounted) context.pop();
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(checkoutCustomerProvider.notifier);
    final customer = await notifier.create(
      fullName: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
    );
    if (customer == null || !mounted) return;
    final success = await notifier.applyCustomer(customer);
    if (success && mounted) context.pop();
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PaymentMethodStyle.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELECT / ADD CUSTOMER',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: PaymentMethodStyle.navy)),
                const Text.rich(TextSpan(children: [
                  TextSpan(
                      text:
                          'Select an existing customer or add a new customer '),
                  TextSpan(
                      text: '(Optional)',
                      style: TextStyle(color: PaymentMethodStyle.orange)),
                ])),
              ],
            ),
          ),
          OutlinedButton.icon(
            key: const ValueKey('checkout-customer-back'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Payment'),
          ),
        ],
      );
}

class _CustomerSearchPanel extends StatelessWidget {
  const _CustomerSearchPanel({
    required this.state,
    required this.selected,
    required this.controller,
    required this.canView,
    required this.onChanged,
    required this.onSubmitted,
    required this.onRetry,
    required this.onLoadMore,
    required this.onSelect,
    required this.onWalkIn,
  });

  final CheckoutCustomerState state;
  final PosCustomer? selected;
  final TextEditingController controller;
  final bool canView;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<PosCustomer?> onSelect;
  final VoidCallback? onWalkIn;

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'FIND EXISTING CUSTOMER',
        child: Column(
          children: [
            if (!canView)
              const Expanded(
                child: _MessageState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Customer search is not available',
                  message: 'customers.view permission is required.',
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      textField: true,
                      label: 'Search customers by name, phone, or email',
                      child: TextField(
                        key: const ValueKey('checkout-customer-search'),
                        controller: controller,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search by name, phone or email...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: TenantAdminColors.border),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Tooltip(
                    message:
                        'Checkout customer filters are not supported by the current contract.',
                    child: OutlinedButton.icon(
                      key: const ValueKey('checkout-customer-filter'),
                      onPressed: null,
                      icon: const Icon(Icons.filter_alt_outlined),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(104, 48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: _results(context)),
              if (onWalkIn != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: state.isApplying ? null : onWalkIn,
                    icon: const Icon(Icons.person_off_outlined),
                    label: const Text('Use Walk-in Customer'),
                  ),
                ),
              ],
              if (state.hasMore) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const ValueKey('checkout-customer-load-more'),
                    onPressed: state.isLoadingMore ? null : onLoadMore,
                    icon: state.isLoadingMore
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                    label: const Text('Load More Customers'),
                  ),
                ),
              ],
            ],
          ],
        ),
      );

  Widget _results(BuildContext context) {
    if (state.isLoading) {
      return const _MessageState(
        key: ValueKey('checkout-customer-loading'),
        icon: Icons.hourglass_top_rounded,
        title: 'Loading customers...',
        progress: true,
      );
    }
    if (state.searchError != null) {
      return _MessageState(
        key: const ValueKey('checkout-customer-search-error'),
        icon: Icons.error_outline_rounded,
        title: 'Unable to load customers',
        message: state.searchError!,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }
    if (state.items.isEmpty) {
      return const _MessageState(
        key: ValueKey('checkout-customer-empty'),
        icon: Icons.person_search_rounded,
        title: 'No customers found',
        message: 'Try another name, phone number, or email.',
      );
    }
    return ListView.separated(
      key: const ValueKey('checkout-customer-results'),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = state.items[index];
        final isSelected = selected?.customerId == customer.customerId;
        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Select ${customer.displayName}',
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              key: ValueKey('checkout-customer-${customer.customerId}'),
              minTileHeight: 64,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              selected: isSelected,
              selectedTileColor: const Color(0xFFFFF0EA),
              leading: CircleAvatar(child: Text(customer.initials)),
              title: Text(customer.displayName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(customer.phone?.trim().isNotEmpty == true
                  ? customer.phone!
                  : 'No phone available'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customer.totalOrderCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            customer.statusLabel,
                            style: const TextStyle(
                              color: PaymentMethodStyle.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${customer.totalOrderCount} ${customer.totalOrderCount == 1 ? 'Order' : 'Orders'}',
                            style: TenantAdminTextStyles.muted(context),
                          ),
                        ],
                      ),
                    ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: isSelected ? PaymentMethodStyle.orange : null,
                  ),
                ],
              ),
              onTap: state.isApplying ? null : () => onSelect(customer),
            ),
          ),
        );
      },
    );
  }
}

class _CreateCustomerPanel extends StatelessWidget {
  const _CreateCustomerPanel({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.canCreate,
    required this.state,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool canCreate;
  final CheckoutCustomerState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'ADD NEW CUSTOMER',
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canCreate)
                  const _InlineNotice(
                    icon: Icons.lock_outline_rounded,
                    text:
                        'customers.create permission is required to add a customer.',
                  ),
                _field(
                  key: const ValueKey('checkout-customer-name'),
                  controller: nameController,
                  label: 'Full Name *',
                  hint: 'Enter full name',
                  icon: Icons.person_outline_rounded,
                  maxLength: 150,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Full name is required'
                      : null,
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                _field(
                  key: const ValueKey('checkout-customer-phone'),
                  controller: phoneController,
                  label: 'Mobile Number *',
                  hint: 'Enter mobile number',
                  icon: Icons.phone_outlined,
                  maxLength: 50,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return 'Mobile number is required';
                    if (RegExp(r'\d').allMatches(phone).length < 7) {
                      return 'Enter a valid mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                _field(
                  key: const ValueKey('checkout-customer-email'),
                  controller: emailController,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
                  maxLength: 150,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return null;
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Enter a valid email address';
                  },
                ),
                if (state.createError != null) ...[
                  const SizedBox(height: 12),
                  _InlineNotice(
                    key: const ValueKey('checkout-customer-create-error'),
                    icon: Icons.error_outline_rounded,
                    text: state.createError!,
                    error: true,
                  ),
                ],
                if (state.applyError != null) ...[
                  const SizedBox(height: 12),
                  _InlineNotice(
                    key: const ValueKey('checkout-customer-apply-error'),
                    icon: Icons.error_outline_rounded,
                    text: state.applyError!,
                    error: true,
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    key: const ValueKey('checkout-customer-add'),
                    onPressed:
                        canCreate && !state.isCreating && !state.isApplying
                            ? onSubmit
                            : null,
                    icon: state.isCreating || state.isApplying
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add Customer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PaymentMethodStyle.orange,
                    ),
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: PaymentMethodStyle.orange,
                    ),
                    SizedBox(width: TenantAdminSpacing.sm),
                    Flexible(
                      child: Text(
                        'The customer will be automatically added to this sale.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PaymentMethodStyle.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  static Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int maxLength,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RequiredFieldLabel(label: label),
          const SizedBox(height: TenantAdminSpacing.xs),
          TextFormField(
            key: key,
            controller: controller,
            maxLength: maxLength,
            keyboardType: keyboardType,
            textInputAction: keyboardType == TextInputType.emailAddress
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
                vertical: 14,
              ),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: TenantAdminColors.border),
              ),
            ),
            validator: validator,
          ),
        ],
      );
}

class _RequiredFieldLabel extends StatelessWidget {
  const _RequiredFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final required = label.endsWith(' *');
    final plainLabel = required ? label.substring(0, label.length - 2) : label;
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PaymentMethodStyle.navy,
              fontWeight: FontWeight.w700,
            ),
        children: [
          TextSpan(text: plainLabel),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: PaymentMethodStyle.orange),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PaymentMethodStyle.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: PaymentMethodStyle.navy)),
            const SizedBox(height: 14),
            Expanded(child: child),
          ],
        ),
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.progress = false,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? message;
  final bool progress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 44, color: PaymentMethodStyle.orange),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    super.key,
    required this.icon,
    required this.text,
    this.error = false,
  });
  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: error ? Colors.red.shade700 : PaymentMethodStyle.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
