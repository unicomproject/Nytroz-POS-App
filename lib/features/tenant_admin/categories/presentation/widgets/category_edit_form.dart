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

class CategoryEditForm extends ConsumerStatefulWidget {
  const CategoryEditForm({
    super.key,
    required this.category,
    required this.submitting,
    required this.onCancel,
    required this.onSavePressed,
    this.fieldErrors = const {},
    this.globalError,
    this.showImageRetry = false,
    this.onRetryImage,
  });

  final Category category;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSavePressed;
  final Map<String, String> fieldErrors;
  final String? globalError;
  final bool showImageRetry;
  final Future<void> Function()? onRetryImage;

  @override
  ConsumerState<CategoryEditForm> createState() => CategoryEditFormState();
}

class CategoryEditFormState extends ConsumerState<CategoryEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortOrderController;

  late String _status;
  late String? _originalParentCategoryId;
  String? _parentCategoryId;
  String? _parentCategoryName;
  String? _parentHierarchyPath;
  bool _removeExistingImage = false;
  Uint8List? _pendingImageBytes;
  String? _pendingImageFileName;

  late final String _originalName;
  late final String _originalCode;
  late final String _originalDescription;
  late final String _originalSortOrder;
  late final String _originalStatus;

  Uint8List? get pendingImageBytes => _pendingImageBytes;
  String? get pendingImageFileName => _pendingImageFileName;
  String? get originalParentCategoryId => _originalParentCategoryId;
  String? get selectedParentCategoryId => _parentCategoryId;
  bool get parentChanged => _originalParentCategoryId != _parentCategoryId;

  @override
  void initState() {
    super.initState();
    final category = widget.category;

    _originalName = category.categoryName;
    _originalCode = category.categoryCode;
    _originalDescription = category.description ?? '';
    _originalSortOrder = '${category.sortOrder}';
    _originalStatus = category.status.toUpperCase();

    _nameController = TextEditingController(text: category.categoryName);
    _codeController = TextEditingController(text: category.categoryCode);
    _descriptionController =
        TextEditingController(text: category.description ?? '');
    _sortOrderController =
        TextEditingController(text: '${category.sortOrder}');

    _status = category.status.toUpperCase();
    _originalParentCategoryId = category.parentCategoryId;
    _parentCategoryId = category.parentCategoryId;
    _parentCategoryName = category.parentCategoryName;
    _parentHierarchyPath = deriveParentHierarchyPath(category);
  }

  void stagePendingImageForTest(Uint8List bytes, String fileName) {
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageFileName = fileName;
      _removeExistingImage = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  bool get hasUnsavedChanges {
    return _nameController.text.trim() != _originalName ||
        _codeController.text.trim().toUpperCase() != _originalCode ||
        _descriptionController.text.trim() != _originalDescription ||
        _sortOrderController.text.trim() != _originalSortOrder ||
        _status != _originalStatus ||
        _parentCategoryId != _originalParentCategoryId ||
        _pendingImageBytes != null ||
        _removeExistingImage;
  }

  bool _isCurrentParentInactive(List<CategoryParentOption> activeOptions) {
    if (_parentCategoryId == null || _parentCategoryId!.isEmpty) {
      return false;
    }

    return !activeOptions.any((option) => option.id == _parentCategoryId);
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
                categoryId: widget.category.id,
                input: input,
                imageBytes: _pendingImageBytes,
                imageFileName: _pendingImageFileName,
                removeExistingImage: _removeExistingImage,
              );

      if (!mounted) return;

      if (result.imageActionFailed) {
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
      _removeExistingImage = false;
    });
  }

  void removeImage() {
    setState(() {
      _pendingImageBytes = null;
      _pendingImageFileName = null;
      _removeExistingImage = true;
    });
  }

  Widget? _buildImagePreview() {
    if (_pendingImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        child: Image.memory(
          _pendingImageBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    if (!_removeExistingImage && widget.category.hasImage) {
      return categoryImageAvatar(widget.category, size: 120);
    }

    return null;
  }

  String? _imageFileName() {
    if (_pendingImageFileName != null) {
      return _pendingImageFileName;
    }

    if (!_removeExistingImage && widget.category.hasImage) {
      return 'Current category image';
    }

    return null;
  }

  bool get _hasImagePreview =>
      _pendingImageBytes != null ||
      (!_removeExistingImage && widget.category.hasImage);

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final parentOptions = treeAsync.maybeWhen(
      data: (tree) => flattenActiveCategoryTree(tree)
          .where((option) => option.id != widget.category.id)
          .toList(growable: false),
      orElse: () => const <CategoryParentOption>[],
    );
    final parentIsInactive = _isCurrentParentInactive(parentOptions);
    final parentSelectorLabel = formatEditParentSelectorLabel(
      parentId: _parentCategoryId,
      parentName: _parentCategoryName,
      parentIsInactive: parentIsInactive,
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
              widget.globalError?.contains('remove') == true
                  ? 'Category saved, but the image could not be removed.'
                  : 'Category saved, but the image could not be updated.',
              style: const TextStyle(color: TenantAdminColors.warning),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            TenantAdminSecondaryButton(
              label: 'Retry image action',
              loading: widget.submitting,
              onPressed: widget.onRetryImage,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
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
                      selectedLabel: parentSelectorLabel,
                      enabled: !widget.submitting && !widget.showImageRetry,
                      errorText: widget.fieldErrors['parent'],
                      excludeCategoryId: widget.category.id,
                      isEditMode: true,
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
                    fileName: _imageFileName(),
                    preview: _buildImagePreview(),
                    enabled: !widget.submitting && !widget.showImageRetry,
                    onChooseImage: pickImage,
                    onRemoveImage: _hasImagePreview ? removeImage : null,
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
                    label: widget.submitting ? 'Saving...' : 'Save Changes',
                    loading: widget.submitting,
                    onPressed: widget.submitting ? null : widget.onSavePressed,
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
