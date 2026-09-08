import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../products/presentation/navigation/products_sidebar_routes.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import '../utils/category_form_utils.dart';

class CategoryArchiveDialog extends ConsumerStatefulWidget {
  const CategoryArchiveDialog({
    super.key,
    required this.category,
    this.navigateToListOnSuccess = false,
    this.onSuccess,
    this.navigationRouter,
  });

  final Category category;
  final bool navigateToListOnSuccess;
  final VoidCallback? onSuccess;
  final GoRouter? navigationRouter;

  static Future<bool?> show({
    required BuildContext context,
    required Category category,
    bool navigateToListOnSuccess = false,
    VoidCallback? onSuccess,
  }) {
    final navigationRouter = GoRouter.maybeOf(context);

    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => CategoryArchiveDialog(
        category: category,
        navigateToListOnSuccess: navigateToListOnSuccess,
        onSuccess: onSuccess,
        navigationRouter: navigationRouter,
      ),
    );
  }

  @override
  ConsumerState<CategoryArchiveDialog> createState() =>
      _CategoryArchiveDialogState();
}

class _CategoryArchiveDialogState extends ConsumerState<CategoryArchiveDialog> {
  var _submitting = false;

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.category.categoryName.trim().isEmpty
        ? 'Category'
        : widget.category.categoryName;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      backgroundColor: TenantAdminColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: 'Archive category warning',
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: TenantAdminColors.danger.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.archive_outlined,
                        size: 20,
                        color: TenantAdminColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: Text(
                      'Archive Category',
                      style: TenantAdminTextStyles.sectionTitle(context),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(false),
                    tooltip: 'Close',
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: TenantAdminColors.mutedText,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                'Are you sure you want to archive "$categoryName"?',
                style: TenantAdminTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                'This category will no longer be available for normal Category Management or new Product Setup selection.',
                style: TenantAdminTextStyles.muted(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: TenantAdminSpacing.sm,
                runSpacing: TenantAdminSpacing.sm,
                children: [
                  TenantAdminSecondaryButton(
                    label: 'Cancel',
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  TenantAdminPrimaryButton(
                    label: 'Archive Category',
                    icon: Icons.archive_outlined,
                    loading: _submitting,
                    backgroundColor: TenantAdminColors.danger,
                    onPressed: _submitting ? null : _archive,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _archive() async {
    if (_submitting) {
      return;
    }

    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = widget.navigationRouter;

    try {
      await ref
          .read(categorySaveControllerProvider.notifier)
          .archive(widget.category.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);

      if (widget.navigateToListOnSuccess && router != null) {
        router.go(ProductsSidebarRoutes.categories);
      }

      _showSnackBar(
        messenger,
        const SnackBar(content: Text('Category archived successfully.')),
      );

      widget.onSuccess?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (isCategoryNotFoundError(error)) {
        Navigator.of(context).pop(false);
        ref.invalidate(categoryListProvider);
        ref.invalidate(categoryTreeProvider);
        ref.invalidate(categoryDetailsProvider(widget.category.id));

        _showSnackBar(
          messenger,
          SnackBar(
            content: Text(categoryArchiveErrorMessage(error)),
            backgroundColor: TenantAdminColors.danger,
          ),
        );

        if (widget.navigateToListOnSuccess && router != null) {
          router.go(ProductsSidebarRoutes.categories);
        }
        return;
      }

      setState(() => _submitting = false);

      _showSnackBar(
        messenger,
        SnackBar(
          content: Text(categoryArchiveErrorMessage(error)),
          backgroundColor: TenantAdminColors.danger,
        ),
      );
    }
  }

  void _showSnackBar(ScaffoldMessengerState? messenger, SnackBar snackBar) {
    if (messenger == null) {
      return;
    }

    try {
      messenger.showSnackBar(snackBar);
    } catch (_) {}
  }
}
