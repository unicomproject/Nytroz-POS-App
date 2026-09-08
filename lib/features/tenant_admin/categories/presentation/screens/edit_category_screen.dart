import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/category.dart';
import '../../../products/presentation/navigation/products_sidebar_routes.dart';
import '../providers/category_providers.dart' hide categoryApiErrorMessage;
import '../providers/category_visibility_provider.dart';
import '../utils/category_form_utils.dart';
import '../widgets/category_edit_form.dart';

enum _PendingImageAction { upload, remove }

class EditCategoryScreen extends ConsumerStatefulWidget {
  const EditCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
  final _formKey = GlobalKey<CategoryEditFormState>();
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _globalError;
  var _showImageRetry = false;
  _PendingImageAction? _pendingImageAction;
  Uint8List? _pendingRetryImageBytes;
  String? _pendingRetryImageFileName;
  Category? _savedCategory;

  Future<void> _goBackToList({required bool confirmIfDirty}) async {
    final formState = _formKey.currentState;
    if (confirmIfDirty &&
        formState != null &&
        formState.hasUnsavedChanges &&
        !_showImageRetry) {
      final discard = await confirmDiscardCategoryForm(context);
      if (!discard || !mounted) return;
    }

    if (mounted) {
      context.go(ProductsSidebarRoutes.categories);
    }
  }

  void _handlePartialSuccess(CategorySaveResult result) {
    final formState = _formKey.currentState;
    setState(() {
      _savedCategory = result.category;
      _showImageRetry = true;
      _globalError = result.imageUploadError;
      if (result.imageRemoveFailed) {
        _pendingImageAction = _PendingImageAction.remove;
      } else if (result.imageUploadFailed) {
        _pendingImageAction = _PendingImageAction.upload;
        _pendingRetryImageBytes = formState?.pendingImageBytes;
        _pendingRetryImageFileName = formState?.pendingImageFileName;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.imageRemoveFailed
              ? 'Category saved, but the image could not be removed.'
              : 'Category saved, but the image could not be updated.',
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    setState(() {
      _submitting = true;
      _fieldErrors = const {};
      _globalError = null;
    });

    await formState.submit(
      onSuccess: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully.')),
        );
        context.go(ProductsSidebarRoutes.categoryDetail(widget.categoryId));
      },
      onPartialSuccess: _handlePartialSuccess,
      onError: (error, fieldErrors) {
        if (!mounted) return;
        setState(() {
          _fieldErrors = fieldErrors;
          _globalError =
              fieldErrors.isEmpty ? categoryApiErrorMessage(error) : null;
        });
      },
    );

    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  Future<void> _retryImageAction() async {
    final categoryId = _savedCategory?.id ?? widget.categoryId;
    setState(() => _submitting = true);

    try {
      if (_pendingImageAction == _PendingImageAction.remove) {
        await ref
            .read(categorySaveControllerProvider.notifier)
            .retryImageRemove(categoryId: categoryId);
      } else {
        final bytes = _pendingRetryImageBytes;
        if (bytes == null) return;

        await ref.read(categorySaveControllerProvider.notifier).retryImageUpload(
              categoryId: categoryId,
              imageBytes: bytes,
              imageFileName: _pendingRetryImageFileName ?? 'category.jpg',
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category image updated successfully.')),
      );
      context.go(ProductsSidebarRoutes.categoryDetail(widget.categoryId));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _globalError = categoryApiErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageTitle = 'Edit Category';
    const pageSubtitle =
        'Update category information and hierarchy settings.';

    final canUpdate = ref.watch(categoryUpdateAccessProvider);
    final categoryAsync = ref.watch(categoryDetailsProvider(widget.categoryId));
    final treeState = ref.watch(categoryTreeProvider);

    if (!canUpdate) {
      return TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            icon: Icons.arrow_back,
            onPressed: () => context.go(ProductsSidebarRoutes.categories),
          ),
        ],
        child: const TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to edit categories.',
          icon: Icons.category_outlined,
        ),
      );
    }

    return categoryAsync.when(
      loading: () => TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            icon: Icons.arrow_back,
            onPressed: () => context.go(ProductsSidebarRoutes.categories),
          ),
        ],
        child: const TenantAdminLoadingSkeleton(rowCount: 10),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            icon: Icons.arrow_back,
            onPressed: () => context.go(ProductsSidebarRoutes.categories),
          ),
        ],
        child: isCategoryNotFoundError(error)
            ? const TenantAdminEmptyState(
                title: 'Category not found',
                message: 'The requested category could not be found.',
                icon: Icons.search_off_outlined,
              )
            : TenantAdminErrorState(
                title: 'Unable to load category',
                message: categoryApiErrorMessage(error),
                onRetry: () =>
                    ref.invalidate(categoryDetailsProvider(widget.categoryId)),
              ),
      ),
      data: (category) => TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        scrollable: false,
        fillHeight: true,
        headerSpacing: TenantAdminSpacing.sm,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            icon: Icons.arrow_back,
            onPressed: () => _goBackToList(confirmIfDirty: true),
          ),
        ],
        child: treeState.when(
          loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
          error: (error, _) => TenantAdminErrorState(
            title: 'Unable to load parent categories',
            message: categoryApiErrorMessage(error),
            onRetry: () => ref.invalidate(categoryTreeProvider),
          ),
          data: (_) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              decoration: BoxDecoration(
                color: TenantAdminColors.surface,
                borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                border: Border.all(color: TenantAdminColors.border),
                boxShadow: TenantAdminShadows.card,
              ),
              child: CategoryEditForm(
                key: _formKey,
                category: category,
                submitting: _submitting,
                fieldErrors: _fieldErrors,
                globalError: _globalError,
                showImageRetry: _showImageRetry,
                onRetryImage: _retryImageAction,
                onCancel: () => _goBackToList(confirmIfDirty: true),
                onSavePressed: _handleSubmit,
              ),
            );
          },
        ),
      ),
    );
  }
}
