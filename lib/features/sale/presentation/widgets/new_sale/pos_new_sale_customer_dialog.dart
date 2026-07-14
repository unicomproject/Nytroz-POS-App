import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/data/datasources/pos_customer_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

Future<PosCustomer?> showPosNewSaleCustomerDialog({
  required BuildContext context,
  required WidgetRef ref,
  required bool canCreateCustomer,
}) {
  final container = ProviderScope.containerOf(context, listen: false);

  return showAppDialog<PosCustomer>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: _PosNewSaleCustomerDialog(
        canCreateCustomer: canCreateCustomer,
      ),
    ),
  );
}

class _PosNewSaleCustomerDialog extends ConsumerStatefulWidget {
  const _PosNewSaleCustomerDialog({
    required this.canCreateCustomer,
  });

  final bool canCreateCustomer;

  @override
  ConsumerState<_PosNewSaleCustomerDialog> createState() =>
      _PosNewSaleCustomerDialogState();
}

class _PosNewSaleCustomerDialogState
    extends ConsumerState<_PosNewSaleCustomerDialog> {
  final _quickAddFormKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isCreating = false;
  String _errorMessage = '';
  List<PosCustomer> _customers = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Dialog(
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 620,
            maxHeight: 720,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Customer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: TenantAdminColors.bodyText,
                                  fontWeight: FontWeight.w900,
                                ) ??
                            const TextStyle(
                              color: TenantAdminColors.bodyText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                _SearchBar(
                  controller: _searchController,
                  isLoading: _isLoading,
                  onSearch: _loadCustomers,
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCustomerContent(context),
                        const SizedBox(height: TenantAdminSpacing.lg),
                        const Divider(),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        _buildQuickAddSection(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerContent(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: TenantAdminSpacing.md),
              Text('Loading customers...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _CustomerMessagePanel(
        icon: Icons.error_outline_rounded,
        title: _errorMessage,
        actionLabel: 'Retry',
        onAction: _loadCustomers,
      );
    }

    if (_customers.isEmpty) {
      return const _CustomerMessagePanel(
        icon: Icons.person_search_rounded,
        title: 'No customers found',
        message: 'Use Quick Add Customer below to create a new customer.',
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _customers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final customer = _customers[index];
          final subtitle = [customer.phone, customer.email]
              .where((value) => value?.trim().isNotEmpty == true)
              .join(' • ');

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline_rounded),
            ),
            title: Text(
              customer.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle.isEmpty
                ? null
                : Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => Navigator.of(context).pop(customer),
          );
        },
      ),
    );
  }

  Widget _buildQuickAddSection(BuildContext context) {
    return Form(
      key: _quickAddFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Add Customer',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Name'),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            textInputAction: TextInputAction.done,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return null;
              }
              final isValid =
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
              return isValid ? null : 'Enter a valid email';
            },
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          PosPrimaryActionButton(
            onPressed: widget.canCreateCustomer && !_isCreating
                ? _createCustomer
                : null,
            icon: Icons.person_add_alt_1_rounded,
            isLoading: _isCreating,
            label: 'Create Customer',
          ),
        ],
      ),
    );
  }

  Future<void> _loadCustomers() async {
    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      setState(() {
        _isLoading = false;
        _customers = [];
        _errorMessage = 'Device context is not available.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final datasource = PosCustomerRemoteDatasource(ref.read(appDioProvider));
      final customers = await datasource.searchCustomers(
        deviceId: deviceContext.deviceId,
        search: _searchController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = customers;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = [];
        _errorMessage = 'Unable to load customers. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createCustomer() async {
    if (!_quickAddFormKey.currentState!.validate()) {
      return;
    }

    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      setState(() => _errorMessage = 'Device context is not available.');
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = '';
    });

    try {
      final datasource = PosCustomerRemoteDatasource(ref.read(appDioProvider));
      final customer = await datasource.createCustomer(
        deviceId: deviceContext.deviceId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emptyToNull(_emailController.text),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(customer);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to create customer. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Search by name or phone number',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        FilledButton.icon(
          onPressed: isLoading ? null : onSearch,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Search'),
        ),
      ],
    );
  }
}

class _CustomerMessagePanel extends StatelessWidget {
  const _CustomerMessagePanel({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: TenantAdminColors.offline),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (message != null) ...[
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
