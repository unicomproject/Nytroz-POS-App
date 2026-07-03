import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/product.dart';
import '../providers/product_local_image_provider.dart';
import '../providers/product_providers.dart';
import '../providers/product_visibility_provider.dart';
import '../utils/product_api_errors.dart';
import '../utils/product_list_filters.dart';
import '../widgets/product_form.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<ProductFormState>();
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  Future<void> _handleSave() async {
    final submitted = await _formKey.currentState?.submit() ?? false;
    if (!submitted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the required fields.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authHeaderSyncProvider);
    final visibilityState = ref.watch(addProductFormVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Add New Product',
        subtitle: 'Fill in the product details below to add a new product.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Add New Product',
        subtitle: 'Fill in the product details below to add a new product.',
        child: TenantAdminErrorState(
          title: 'Unable to load permissions',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(addProductFormVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Add Product',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to create products.',
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: 'Add New Product',
          subtitle: 'Fill in the product details below to add a new product.',
          actions: [
            ProductFormHeaderActions(
              visibility: visibility,
              submitting: _submitting,
              onCancel: () => context.go('/tenant-admin/products'),
              onSave: _handleSave,
            ),
          ],
          child: ProductForm(
            key: _formKey,
            visibility: visibility,
            backendErrors: _fieldErrors,
            submitting: _submitting,
            onCancel: () => context.go('/tenant-admin/products'),
            onSave: _handleSave,
            onSubmit: _submit,
          ),
        );
      },
    );
  }

  Future<bool> _submit(ProductFormData form) async {
    final imageDraft = _formKey.currentState?.imageDraft;

    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    try {
      final created = await ref.read(createProductProvider).call(form);

      var imageUploaded = false;
      if (imageDraft != null) {
        ref.read(productLocalImageCacheProvider.notifier).save(
              created.id,
              imageDraft.bytes,
            );

        try {
          await ref.read(productRepositoryProvider).uploadProductImage(
                productId: created.id,
                bytes: imageDraft.bytes,
                fileName: imageDraft.fileName,
              );
          imageUploaded = true;
        } on DioException catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  uploadError.response?.statusCode == 404
                      ? 'Product saved, but image upload API is not available yet.'
                      : 'Product saved, but image upload failed: '
                          '${productErrorMessage(uploadError, fallback: 'Upload failed')}',
                ),
              ),
            );
          }
        }
      }

    ref.read(productPageProvider.notifier).state = 1;
ref.read(productSearchProvider.notifier).state = '';
ref.read(productStatusFilterProvider.notifier).state =
    ProductStatusFilter.all;

ref.invalidate(productListProvider);
await ref.read(productListProvider.future);

if (!mounted) {
  return true;    
}

      if (imageDraft == null || imageUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageDraft != null
                  ? 'Product created and image uploaded successfully.'
                  : 'Product created successfully.',
            ),
          ),
        );
      }

      context.go('/tenant-admin/products');
      return true;
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
        return false;
      }

      final fieldErrors = productValidationErrors(error);
      setState(() => _fieldErrors = fieldErrors);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              productSubmitErrorMessage(
                error,
                fieldErrors,
                fallback: 'Failed to create product',
              ),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
