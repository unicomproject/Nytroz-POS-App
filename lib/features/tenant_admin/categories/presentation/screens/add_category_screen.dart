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
import '../widgets/category_add_form.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _formKey = GlobalKey<CategoryAddFormState>();
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _globalError;
  String? _createdCategoryId;
  var _showImageRetry = false;
  Uint8List? _pendingRetryImageBytes;
  String? _pendingRetryImageFileName;

  Future<void> _goBackToList({required bool confirmIfDirty}) async {
    final formState = _formKey.currentState;
    if (confirmIfDirty &&
        formState != null &&
        formState.hasUnsavedChanges &&
        _createdCategoryId == null) {
      final discard = await confirmDiscardCategoryForm(context);
      if (!discard || !mounted) return;
    }

    if (mounted) {
      context.go(ProductsSidebarRoutes.categories);
    }
  }

  void _handlePartialSuccess(CategorySaveResult result, CategoryAddFormState form) {
    setState(() {
      _createdCategoryId = result.category.id;
      _showImageRetry = true;
      _pendingRetryImageBytes = form.pendingImageBytes;
      _pendingRetryImageFileName = form.pendingImageFileName;
      _globalError = result.imageUploadError;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Category created successfully, but the image could not be uploaded.',
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
          const SnackBar(content: Text('Category created successfully.')),
        );
        context.go(ProductsSidebarRoutes.categories);
      },
      onPartialSuccess: (result) => _handlePartialSuccess(result, formState),
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

  Future<void> _retryImageUpload() async {
    final categoryId = _createdCategoryId;
    final bytes = _pendingRetryImageBytes;
    if (categoryId == null || bytes == null) return;

    setState(() => _submitting = true);

    try {
      await ref.read(categorySaveControllerProvider.notifier).retryImageUpload(
            categoryId: categoryId,
            imageBytes: bytes,
            imageFileName: _pendingRetryImageFileName ?? 'category.jpg',
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category image uploaded successfully.')),
      );
      context.go(ProductsSidebarRoutes.categories);
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
    final hasAccess = ref.watch(categoryAddPageAccessProvider);
    final treeState = ref.watch(categoryTreeProvider);

    if (!hasAccess) {
      return const TenantAdminPageScaffold(
        title: 'Add Category',
        subtitle:
            'Create a new product category using a parent-child hierarchy.',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to create categories.',
          icon: Icons.category_outlined,
        ),
      );
    }

    return TenantAdminPageScaffold(
      title: 'Add Category',
      subtitle: 'Create a new product category using a parent-child hierarchy.',
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
            child: CategoryAddForm(
              key: _formKey,
              submitting: _submitting,
              fieldErrors: _fieldErrors,
              globalError: _globalError,
              showImageRetry: _showImageRetry,
              onRetryImage: _retryImageUpload,
              onCancel: () => _goBackToList(confirmIfDirty: true),
              onCreatePressed: _handleSubmit,
              onBackToListAfterPartial: () =>
                  context.go(ProductsSidebarRoutes.categories),
            ),
          );
        },
      ),
    );
  }
}
