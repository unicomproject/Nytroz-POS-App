import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree_node.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/category_providers.dart';

String formatCategoryUpdatedOn(DateTime? value) {
  if (value == null) {
    return '—';
  }

  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$minute $period';
}

Widget categoryImageAvatar(Category category, {double size = 40}) {
  final url = category.imageUrl?.trim();
  if (url == null || url.isEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TenantAdminColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      child: Icon(Icons.category_outlined, size: size * 0.45),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: TenantAdminColors.border.withValues(alpha: 0.35),
        child: Icon(Icons.broken_image_outlined, size: size * 0.45),
      ),
    ),
  );
}

Future<void> openCategoryDetailsPanel({
  required BuildContext context,
  Category? existing,
  required bool canSave,
  bool readOnly = false,
}) {
  final isMobile =
      MediaQuery.sizeOf(context).width < TenantAdminBreakpoints.smallTablet;

  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.95,
        child: CategoryDetailsSidePanel(
          existing: existing,
          canSave: canSave,
          readOnly: readOnly,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close category details',
    barrierColor: Colors.black54,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: TenantAdminColors.surface,
          elevation: 8,
          child: SizedBox(
            width: 420,
            height: double.infinity,
            child: CategoryDetailsSidePanel(
              existing: existing,
              canSave: canSave,
              readOnly: readOnly,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    },
  );
}

class CategoryDetailsSidePanel extends ConsumerStatefulWidget {
  const CategoryDetailsSidePanel({
    super.key,
    this.existing,
    required this.canSave,
    required this.onClose,
    this.readOnly = false,
  });

  final Category? existing;
  final bool canSave;
  final VoidCallback onClose;
  final bool readOnly;

  @override
  ConsumerState<CategoryDetailsSidePanel> createState() =>
      _CategoryDetailsSidePanelState();
}

class _CategoryDetailsSidePanelState
    extends ConsumerState<CategoryDetailsSidePanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortOrderController;
  late String _status;
  String? _parentCategoryId;
  String? _parentCategoryName;
  bool _codeEditedManually = false;
  bool _saving = false;
  bool _removeExistingImage = false;
  Uint8List? _pendingImageBytes;
  String? _pendingImageFileName;
  String? _errorMessage;
  String? _savedCategoryIdForImageRetry;
  bool _showImageRetry = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.categoryName ?? '');
    _codeController =
        TextEditingController(text: widget.existing?.categoryCode ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _sortOrderController = TextEditingController(
      text: '${widget.existing?.sortOrder ?? 0}',
    );
    _status = widget.existing?.status.toUpperCase() ?? 'ACTIVE';
    _parentCategoryId = widget.existing?.parentCategoryId;
    _parentCategoryName = widget.existing?.parentCategoryName;
    _codeEditedManually = widget.existing != null;
    _savedCategoryIdForImageRetry = widget.existing?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;
  bool get _isViewOnly => widget.readOnly || !widget.canSave;

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isViewOnly
                      ? 'Category Details'
                      : (_isEdit ? 'Edit Category' : 'Add Category'),
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _saving ? null : widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _isViewOnly && widget.existing != null
                ? _buildReadOnlyDetails(widget.existing!)
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: !_saving,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            labelText: 'Category Name *',
                            border: OutlineInputBorder(),
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
                          enabled: !_saving,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'Category Code *',
                            border: OutlineInputBorder(),
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
                            style: const TextStyle(
                              color: TenantAdminColors.danger,
                            ),
                          ),
                          data: (tree) => _ParentCategoryField(
                            tree: tree,
                            selectedId: _parentCategoryId,
                            selectedName: _parentCategoryName,
                            existingCategoryId: widget.existing?.id,
                            enabled: !_saving,
                            onChanged: (id, name) {
                              setState(() {
                                _parentCategoryId = id;
                                _parentCategoryName = name;
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
                          onChanged: _saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_saving,
                          maxLines: 4,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        TenantAdminSingleImageUploadCard(
                          title: 'Category Image',
                          description:
                              'Optional image shown with this category.',
                          fileName: _pendingImageFileName ??
                              ((_pendingImageBytes != null ||
                                      (widget.existing?.hasImage ?? false))
                                  ? 'Current category image'
                                  : null),
                          preview: _pendingImageBytes != null ||
                                  (widget.existing?.hasImage ?? false)
                              ? _buildImagePreview()
                              : null,
                          enabled: !_saving,
                          onChooseImage: _pickImage,
                          onRemoveImage: widget.existing?.hasImage == true
                              ? () {
                                  setState(() {
                                    _pendingImageBytes = null;
                                    _pendingImageFileName = null;
                                    _removeExistingImage = true;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        TextFormField(
                          controller: _sortOrderController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sort Order',
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
                        if (_errorMessage != null) ...[
                          const SizedBox(height: TenantAdminSpacing.md),
                          Text(
                            _errorMessage!,
                            style:
                                const TextStyle(color: TenantAdminColors.danger),
                          ),
                        ],
                        if (_showImageRetry) ...[
                          const SizedBox(height: TenantAdminSpacing.md),
                          Text(
                            'Category saved, but image upload failed.',
                            style: const TextStyle(
                              color: TenantAdminColors.warning,
                            ),
                          ),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          TenantAdminSecondaryButton(
                            label: 'Retry image upload',
                            onPressed: _saving ? null : _retryImageUpload,
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
        if (!_isViewOnly) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : widget.onClose,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: TenantAdminPrimaryButton(
                    label: _saving ? 'Saving...' : 'Save Category',
                    onPressed: _saving ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadOnlyDetails(Category category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: categoryImageAvatar(category, size: 96)),
        const SizedBox(height: TenantAdminSpacing.lg),
        _ReadOnlyField(label: 'Category Name', value: category.categoryName),
        _ReadOnlyField(label: 'Category Code', value: category.categoryCode),
        _ReadOnlyField(
          label: 'Status',
          valueWidget: TenantAdminStatusBadge(
            label: category.isActive ? 'Active' : 'Inactive',
            status: category.isActive
                ? TenantAdminStatusType.active
                : TenantAdminStatusType.inactive,
          ),
        ),
        _ReadOnlyField(
          label: 'Parent Category',
          value: category.parentDisplayLabel,
        ),
        _ReadOnlyField(label: 'Level', value: '${category.level}'),
        _ReadOnlyField(label: 'Hierarchy Path', value: category.hierarchyPath),
        if (category.description?.trim().isNotEmpty == true)
          _ReadOnlyField(label: 'Description', value: category.description!),
        _ReadOnlyField(label: 'Sort Order', value: '${category.sortOrder}'),
        _ReadOnlyField(
          label: 'Child Categories',
          value: '${category.childCount}',
        ),
        _ReadOnlyField(label: 'Product Count', value: '${category.productCount}'),
        _ReadOnlyField(
          label: 'Created At',
          value: formatCategoryUpdatedOn(category.createdAt),
        ),
        _ReadOnlyField(
          label: 'Updated At',
          value: formatCategoryUpdatedOn(category.updatedAt),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_pendingImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        child: Image.memory(
          _pendingImageBytes!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.existing != null) {
      return categoryImageAvatar(widget.existing!, size: 72);
    }

    return categoryImageAvatar(
      const Category(
        id: '',
        categoryCode: '',
        categoryName: '',
        categorySlug: '',
        status: 'ACTIVE',
        sortOrder: 0,
        level: 1,
        hierarchyPath: '',
        childCount: 0,
        productCount: 0,
        hasChildren: false,
      ),
      size: 72,
    );
  }

  Future<void> _pickImage() async {
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
      _showImageRetry = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

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
                categoryId: widget.existing?.id,
                input: input,
                imageBytes: _pendingImageBytes,
                imageFileName: _pendingImageFileName,
                removeExistingImage: _removeExistingImage,
              );

      if (!mounted) return;

      if (result.imageUploadFailed) {
        setState(() {
          _savedCategoryIdForImageRetry = result.category.id;
          _showImageRetry = true;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Category saved, but image upload failed.',
            ),
          ),
        );
        return;
      }

      widget.onClose();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Category updated successfully.'
                : 'Category created successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = categoryApiErrorMessage(error);
      });
    }
  }

  Future<void> _retryImageUpload() async {
    final categoryId = _savedCategoryIdForImageRetry;
    if (categoryId == null ||
        categoryId.isEmpty ||
        _pendingImageBytes == null) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(categorySaveControllerProvider.notifier).retryImageUpload(
            categoryId: categoryId,
            imageBytes: _pendingImageBytes!,
            imageFileName: _pendingImageFileName ?? 'category.jpg',
          );

      if (!mounted) return;
      widget.onClose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category image uploaded successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = categoryApiErrorMessage(error);
      });
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TenantAdminTextStyles.fieldLabel(context)),
          const SizedBox(height: 4),
          valueWidget ??
              Text(
                value ?? '—',
                style: TenantAdminTextStyles.body(context),
              ),
        ],
      ),
    );
  }
}

class _ParentCategoryField extends StatelessWidget {
  const _ParentCategoryField({
    required this.tree,
    required this.selectedId,
    required this.selectedName,
    required this.onChanged,
    this.existingCategoryId,
    this.enabled = true,
  });

  final List<CategoryTreeNode> tree;
  final String? selectedId;
  final String? selectedName;
  final String? existingCategoryId;
  final bool enabled;
  final void Function(String? id, String? name) onChanged;

  @override
  Widget build(BuildContext context) {
    final options = _buildParentOptions(tree);

    final selectedKey = selectedId ?? 'root';
    final hasSelected = selectedId == null ||
        options.any((option) => option.id == selectedId) ||
        selectedKey == 'root';

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Parent Category',
        helperText: 'Leave as Root Category for a top-level category.',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: hasSelected ? selectedKey : 'root',
          onChanged: !enabled
              ? null
              : (value) {
                  if (value == null || value == 'root') {
                    onChanged(null, null);
                    return;
                  }
                  final match = options.firstWhere((item) => item.id == value);
                  onChanged(match.id, match.name);
                },
          items: [
            const DropdownMenuItem(
              value: 'root',
              child: Text('Root Category'),
            ),
            ...options.map(
              (option) => DropdownMenuItem(
                value: option.id,
                child: Text(
                  '${'  ' * (option.level - 1)}${option.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<({String id, String name, int level, String status})> _buildParentOptions(
    List<CategoryTreeNode> nodes,
  ) {
    final result = <({String id, String name, int level, String status})>[];

    void walk(List<CategoryTreeNode> items) {
      for (final node in items) {
        if (node.id == existingCategoryId) {
          continue;
        }

        final isCurrentParent =
            selectedId != null && node.id == selectedId;
        final selectable = node.isActive || isCurrentParent;

        if (selectable) {
          result.add((
            id: node.id,
            name: node.categoryName,
            level: node.level,
            status: node.status,
          ));
        }

        if (node.children.isNotEmpty) {
          walk(node.children);
        }
      }
    }

    walk(nodes);

    if (selectedId != null &&
        selectedName != null &&
        !result.any((item) => item.id == selectedId)) {
      result.insert(
        0,
        (
          id: selectedId!,
          name: selectedName!,
          level: 1,
          status: 'INACTIVE',
        ),
      );
    }

    return result;
  }
}

String deriveCategoryCode(String name) {
  final normalized = name
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return normalized.isEmpty ? 'CATEGORY' : normalized;
}
