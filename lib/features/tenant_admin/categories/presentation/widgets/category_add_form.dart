import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/category.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';
import '../providers/category_providers.dart';
import '../utils/category_form_utils.dart';
import 'category_form_support_widgets.dart';
import 'category_parent_selector.dart';

class CategoryAddForm extends ConsumerStatefulWidget {
  const CategoryAddForm({
    super.key,
    required this.submitting,
    required this.onCancel,
    required this.onCreatePressed,
    this.onBackToListAfterPartial,
    this.fieldErrors = const {},
    this.globalError,
    this.showImageRetry = false,
    this.onRetryImage,
  });

  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onCreatePressed;
  final VoidCallback? onBackToListAfterPartial;
  final Map<String, String> fieldErrors;
  final String? globalError;
  final bool showImageRetry;
  final Future<void> Function()? onRetryImage;

  @override
  ConsumerState<CategoryAddForm> createState() => CategoryAddFormState();
}

class CategoryAddFormState extends ConsumerState<CategoryAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  String _status = 'ACTIVE';
  String? _parentCategoryId;
  String? _parentCategoryName;
  String? _parentHierarchyPath;
  bool _codeEditedManually = false;
  Uint8List? _pendingImageBytes;
  String? _pendingImageFileName;

  Uint8List? get pendingImageBytes => _pendingImageBytes;
  String? get pendingImageFileName => _pendingImageFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  bool get hasUnsavedChanges {
    return _nameController.text.trim().isNotEmpty ||
        _codeController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _sortOrderController.text.trim() != '0' ||
        _parentCategoryId != null ||
        _status != 'ACTIVE' ||
        _pendingImageBytes != null;
  }

  Future<void> submit({
    required VoidCallback onSuccess,
    required void Function(CategorySaveResult result) onPartialSuccess,
    required void Function(Object error, Map<String, String> fieldErrors)
        onError,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final input = CategoryUpsertInput(
      categoryCode: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      status: _status,
      parentCategoryId: _parentCategoryId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sortOrder: sortOrder,
    );

    try {
      final result =
          await ref.read(categorySaveControllerProvider.notifier).save(
                input: input,
                imageBytes: _pendingImageBytes,
                imageFileName: _pendingImageFileName,
              );

      if (!mounted) return;

      if (result.imageUploadFailed) {
        onPartialSuccess(result);
        return;
      }

      onSuccess();
    } catch (error) {
      onError(error, categoryFieldErrorsFromError(error));
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageFileName = file.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final parentOptions = treeAsync.maybeWhen(
      data: (tree) => flattenActiveCategoryTree(tree),
      orElse: () => const <CategoryParentOption>[],
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryHierarchyIndicator(
            isRoot: _parentCategoryId == null,
            parentHierarchyPath: _parentHierarchyPath,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          if (widget.globalError != null) ...[
            Text(
              widget.globalError!,
              style: const TextStyle(color: TenantAdminColors.danger),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
          ],
          if (widget.showImageRetry) ...[
            Text(
              'Category created successfully, but the image could not be uploaded.',
              style: TextStyle(color: TenantAdminColors.warning),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TenantAdminSecondaryButton(
                    label: 'Retry image upload',
                    loading: widget.submitting,
                    onPressed: widget.onRetryImage,
                  ),
                ),
                if (widget.onBackToListAfterPartial != null) ...[
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.submitting
                          ? null
                          : widget.onBackToListAfterPartial,
                      child: const Text('Back to List'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
          ],
          Expanded(
            child: CategoryFormScrollableColumns(
              leftColumn: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !widget.submitting && !widget.showImageRetry,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: 'Category Name *',
                      hintText: 'Enter category name',
                      errorText: widget.fieldErrors['name'],
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Category name is required.';
                      }
                      if (value.trim().length > 150) {
                        return 'Category name must be 150 characters or less.';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (!_codeEditedManually) {
                        _codeController.text = deriveCategoryCode(value);
                      }
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _codeController,
                    enabled: !widget.submitting && !widget.showImageRetry,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: 'Category Code *',
                      hintText: 'Enter unique code',
                      errorText: widget.fieldErrors['code'],
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Category code is required.';
                      }
                      if (value.trim().length > 80) {
                        return 'Category code must be 80 characters or less.';
                      }
                      return null;
                    },
                    onChanged: (_) => _codeEditedManually = true,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  treeAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text(
                      categoryApiErrorMessage(error),
                      style: const TextStyle(color: TenantAdminColors.danger),
                    ),
                    data: (_) => CategoryParentSelectorField(
                      options: parentOptions,
                      selectedId: _parentCategoryId,
                      selectedLabel: _parentCategoryName,
                      enabled: !widget.submitting && !widget.showImageRetry,
                      errorText: widget.fieldErrors['parent'],
                      onChanged: (option) {
                        setState(() {
                          _parentCategoryId = option?.id;
                          _parentCategoryName = option?.name;
                          _parentHierarchyPath = option?.displayLabel;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ACTIVE',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: 'INACTIVE',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: widget.submitting || widget.showImageRetry
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _status = value);
                            }
                          },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _sortOrderController,
                    enabled: !widget.submitting && !widget.showImageRetry,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      helperText: 'Lower numbers appear first in the list.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null) {
                        return 'Enter a whole number.';
                      }
                      if (parsed < 0) {
                        return 'Sort order cannot be negative.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              rightColumn: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TenantAdminSingleImageUploadCard(
                    title: 'Category Image',
                    description: 'Optional image shown with this category.',
                    fileName: _pendingImageFileName,
                    preview: _pendingImageBytes != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm),
                            child: Image.memory(
                              _pendingImageBytes!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                    enabled: !widget.submitting && !widget.showImageRetry,
                    onChooseImage: pickImage,
                    onRemoveImage: _pendingImageBytes != null
                        ? () => setState(() {
                              _pendingImageBytes = null;
                              _pendingImageFileName = null;
                            })
                        : null,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !widget.submitting && !widget.showImageRetry,
                    minLines: 4,
                    maxLines: 6,
                    textAlignVertical: TextAlignVertical.top,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.showImageRetry) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: TenantAdminSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.submitting ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: TenantAdminPrimaryButton(
                    label:
                        widget.submitting ? 'Creating...' : 'Create Category',
                    loading: widget.submitting,
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    onPressed: widget.submitting ? null : widget.onCreatePressed,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
