import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/outlet_details.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../utils/outlet_api_errors.dart';
import '../widgets/outlet_form.dart';

class AddOutletScreen extends ConsumerStatefulWidget {
  const AddOutletScreen({super.key});

  @override
  ConsumerState<AddOutletScreen> createState() => _AddOutletScreenState();
}

class _AddOutletScreenState extends ConsumerState<AddOutletScreen> {
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};
  OutletDetails? _createdOutlet;

  @override
  Widget build(BuildContext context) {
    final createdOutlet = _createdOutlet;
    final optionsState = ref.watch(outletCreateOptionsProvider);

    if (createdOutlet != null) {
      return TenantAdminPageScaffold(
        title: 'Create Outlet',
        subtitle: 'The outlet is ready to use.',
        child: _OutletCreatedSuccess(
          outlet: createdOutlet,
          onGoToList: () => context.go('/tenant-admin/outlets'),
          onViewDetails: () =>
              context.go('/tenant-admin/outlets/${createdOutlet.id}'),
          onCreateAnother: () {
            setState(() {
              _createdOutlet = null;
              _fieldErrors = const {};
            });
          },
        ),
      );
    }

    return optionsState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Create Outlet',
        subtitle: 'Set up a new outlet using the wizard.',
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Create Outlet',
        subtitle: 'Set up a new outlet using the wizard.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlet options',
          message: outletLoadErrorMessage(error),
          onRetry: () => ref.invalidate(outletCreateOptionsProvider),
        ),
      ),
      data: (options) => TenantAdminPageScaffold(
        title: 'Create Outlet',
        subtitle: 'Set up a new outlet using the wizard.',
        child: OutletForm(
          createOptions: options,
          backendErrors: _fieldErrors,
          submitting: _submitting,
          onSubmit: _submit,
        ),
      ),
    );
  }

  Future<void> _submit(OutletFormData form) async {
    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    try {
      final outlet = await ref.read(createOutletProvider).call(form);
      ref.refresh(outletListProvider).maybeWhen(orElse: () {});
      if (!mounted) {
        return;
      }
      setState(() => _createdOutlet = outlet);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please sign in again.'),
            ),
          );
          context.go('/tenant-login');
        }
        return;
      }

      final fieldErrors = outletValidationErrors(error);
      setState(() => _fieldErrors = fieldErrors);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outletSubmitErrorMessage(
                error,
                fieldErrors,
                fallback: 'Failed to create outlet',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _OutletCreatedSuccess extends StatelessWidget {
  const _OutletCreatedSuccess({
    required this.outlet,
    required this.onGoToList,
    required this.onViewDetails,
    required this.onCreateAnother,
  });

  final OutletDetails outlet;
  final VoidCallback onGoToList;
  final VoidCallback onViewDetails;
  final VoidCallback onCreateAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: TenantAdminColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: TenantAdminColors.success,
              size: 38,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            'Outlet Created Successfully',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'The new outlet has been added and is ready to use.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: TenantAdminColors.border),
                borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              ),
              child: Wrap(
                spacing: TenantAdminSpacing.xl,
                runSpacing: TenantAdminSpacing.lg,
                children: [
                  _SuccessDetail(
                    icon: Icons.storefront_outlined,
                    label: 'Outlet Name',
                    value: outlet.name,
                  ),
                  _SuccessDetail(
                    icon: Icons.tag,
                    label: 'Outlet Code',
                    value: outlet.code,
                  ),
                  _SuccessDetail(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: outlet.phone ?? 'Not entered',
                  ),
                  _SuccessDetail(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: outlet.email ?? 'Not entered',
                  ),
                  _SuccessDetail(
                    icon: Icons.circle,
                    label: 'Status',
                    value: outlet.status,
                    valueColor: TenantAdminColors.success,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          Row(
            children: [
              TenantAdminSecondaryButton(
                label: 'Go to Outlet List',
                icon: Icons.list,
                onPressed: onGoToList,
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              TenantAdminSecondaryButton(
                label: 'View Outlet Details',
                icon: Icons.visibility_outlined,
                onPressed: onViewDetails,
              ),
              const Spacer(),
              TenantAdminPrimaryButton(
                label: 'Create Another Outlet',
                icon: Icons.add,
                onPressed: onCreateAnother,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessDetail extends StatelessWidget {
  const _SuccessDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
            child: Icon(icon, size: 18, color: TenantAdminColors.primary),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
