import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import '../utils/till_api_errors.dart';
import '../widgets/till_form.dart' show TillForm;

class AddTillScreen extends ConsumerStatefulWidget {
  const AddTillScreen({super.key});

  @override
  ConsumerState<AddTillScreen> createState() => _AddTillScreenState();
}

class _AddTillScreenState extends ConsumerState<AddTillScreen> {
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  Widget build(BuildContext context) {
    ref.watch(authHeaderSyncProvider);
    final canCreate = ref.watch(tillCreateAccessProvider);
    final canViewHardware = ref.watch(tillHardwareViewAccessProvider);
    final canManageHardware = ref.watch(tillHardwareManageAccessProvider);
    final outletsState = ref.watch(tillOutletOptionsProvider);

    if (!canCreate) {
      return const TenantAdminPageScaffold(
        title: 'No access',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to create tills.',
        ),
      );
    }

    return TenantAdminPageScaffold(
      title: 'Add till',
      subtitle: 'Enter the details for the new till.',
      child: outletsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 4),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Unable to load outlets',
          message: _outletLoadErrorMessage(error),
          onRetry: () => ref.invalidate(tillOutletOptionsProvider),
        ),
        data: (outlets) {
          if (outlets.isEmpty) {
            return const TenantAdminEmptyState(
              title: 'No outlets available',
              message: 'Create an outlet before adding a till.',
            );
          }

          return TillForm(
            outlets: outlets,
            showHardwareSection: canViewHardware,
            hardwareReadOnly: !canManageHardware,
            backendErrors: _fieldErrors,
            submitting: _submitting,
            onSubmit: _submit,
          );
        },
      ),
    );
  }

  String _outletLoadErrorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }

    return 'Please try again.';
  }

  Future<void> _submit(TillFormData form) async {
    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    try {
      final createdTill = await ref.read(createTillProvider).call(form);
      ref.invalidate(tillListProvider);
      if (!mounted) {
        return;
      }
      await _showCreatedDialog(createdTill, _outletNameFor(form.outletId));
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

      final fieldErrors = tillValidationErrors(error);
      final duplicateCode = error.response?.statusCode == 409 &&
          (error.response?.data is Map) &&
          (error.response?.data as Map)['code'] == 'till.duplicate_code';

      setState(() {
        _fieldErrors = duplicateCode
            ? {
                ...fieldErrors,
                'code': tillSubmitErrorMessage(
                  error,
                  fieldErrors,
                  fallback: 'Till code already exists for this tenant.',
                ),
              }
            : fieldErrors;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tillSubmitErrorMessage(
                error,
                fieldErrors,
                fallback: 'Failed to create till',
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

  String _outletNameFor(String outletId) {
    final outlets = ref.read(tillOutletOptionsProvider).valueOrNull;
    if (outlets == null) {
      return 'Selected outlet';
    }

    for (final outlet in outlets) {
      if (outlet.id == outletId) {
        return outlet.name;
      }
    }

    return 'Selected outlet';
  }

  Future<void> _showCreatedDialog(
    CreatedTill till,
    String outletName,
  ) {
    return showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _TillCreatedDialog(
          till: till,
          outletName: outletName,
          onClose: () {
            Navigator.of(context).pop();
            context.go('/tenant-admin/tills');
          },
        );
      },
    );
  }
}

class _TillCreatedDialog extends StatelessWidget {
  const _TillCreatedDialog({
    required this.till,
    required this.outletName,
    required this.onClose,
  });

  final CreatedTill till;
  final String outletName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: TenantAdminColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: TenantAdminColors.success,
                  size: 46,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                'Till Created Successfully!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'The till has been saved in the backend.',
                textAlign: TextAlign.center,
                style: TenantAdminTextStyles.muted(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                decoration: BoxDecoration(
                  color: TenantAdminColors.secondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  border: Border.all(color: TenantAdminColors.border),
                ),
                child: Column(
                  children: [
                    _CreatedRow(
                      icon: Icons.point_of_sale_outlined,
                      label: 'Till Name',
                      value: till.name,
                    ),
                    _CreatedRow(
                      icon: Icons.tag,
                      label: 'Till Code',
                      value: till.code,
                    ),
                    _CreatedRow(
                      icon: Icons.location_on_outlined,
                      label: 'Outlet',
                      value: outletName,
                    ),
                    _CreatedRow(
                      icon: Icons.circle,
                      label: 'Status',
                      value: _titleCase(till.status),
                      valueColor: TenantAdminColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              TenantAdminSecondaryButton(
                label: 'Close',
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatedRow extends StatelessWidget {
  const _CreatedRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TenantAdminColors.primary),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: TenantAdminTextStyles.muted(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? TenantAdminColors.bodyText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '—';
  }

  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}
