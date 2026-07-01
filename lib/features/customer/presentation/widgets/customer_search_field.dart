import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../providers/customer_search_provider.dart';

/// Labelled search input for the Add Customer dialog. Updates
/// [customerSearchQueryProvider] as the cashier types.
class CustomerSearchField extends ConsumerStatefulWidget {
  const CustomerSearchField({super.key});

  @override
  ConsumerState<CustomerSearchField> createState() =>
      _CustomerSearchFieldState();
}

class _CustomerSearchFieldState extends ConsumerState<CustomerSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(customerSearchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Customer',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Search by name, phone number or email',
          style: TenantAdminTextStyles.muted(context),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (value) =>
              ref.read(customerSearchQueryProvider.notifier).state = value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w600,
              ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: TenantAdminColors.mutedText,
            ),
            hintText: 'Enter mobile number or name',
            hintStyle: TenantAdminTextStyles.muted(context),
            filled: true,
            fillColor: TenantAdminColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.md,
              vertical: TenantAdminSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(
                color: TenantAdminColors.info,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
