import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../../../brands/domain/entities/brand.dart';
import '../../../../brands/presentation/providers/brand_providers.dart';
import '../../utils/brand_quick_add_utils.dart';

/// Wizard-native Quick Add Brand drawer (R1). Reuses the canonical
/// POST /api/v1/brands create path via [brandSaveControllerProvider] — there is
/// no product-wizard-specific Brand-create endpoint. A Brand created here is a
/// deliberate Tenant Master Data action and remains created even if the wizard
/// itself is later cancelled; only the External Brand Mapping (persisted
/// separately, on successful product create) is conditional on wizard success.
class QuickAddBrandDrawer extends ConsumerStatefulWidget {
  const QuickAddBrandDrawer({
    super.key,
    this.prefillName,
    required this.onCreated,
  });

  /// Prefilled from the external lookup's Brand text, when available.
  final String? prefillName;
  final ValueChanged<Brand> onCreated;

  @override
  ConsumerState<QuickAddBrandDrawer> createState() =>
      _QuickAddBrandDrawerState();
}

class _QuickAddBrandDrawerState extends ConsumerState<QuickAddBrandDrawer> {
  static const int _maxNameLength = 150;
  static const int _maxCodeLength = 80;
  static const int _maxDescriptionLength = 255;

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _sortOrderController;
  final TextEditingController _descriptionController = TextEditingController();

  String _status = 'ACTIVE';
  bool _codeEditedManually = false;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefillName?.trim() ?? '';
    _nameController = TextEditingController(text: prefill);
    _codeController = TextEditingController(
      text: prefill.isEmpty ? '' : deriveBrandCode(prefill),
    );
    _sortOrderController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sortOrderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Brand name is required.');
      return;
    }
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Brand code is required.');
      return;
    }

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final brand = await ref.read(brandSaveControllerProvider.notifier).save(
            input: BrandUpsertInput(
              code: code,
              name: name,
              status: _status,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              sortOrder: sortOrder,
            ),
          );

      if (!mounted) return;
      widget.onCreated(brand);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _friendlyErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('duplicate_code')) {
      return 'Brand code already exists.';
    }
    if (text.contains('duplicate_name')) {
      return 'Brand name already exists.';
    }
    return 'Unable to create brand. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TenantAdminSpacing.lg,
            TenantAdminSpacing.md,
            TenantAdminSpacing.sm,
            TenantAdminSpacing.md,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Quick Add Brand',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: TenantAdminColors.mutedText,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: TenantAdminColors.border),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.md,
                      vertical: TenantAdminSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TenantAdminColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                ],
                _label('Brand Name *'),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('quick_add_brand_name_field'),
                  controller: _nameController,
                  maxLength: _maxNameLength,
                  onChanged: (value) {
                    if (!_codeEditedManually) {
                      _codeController.text = deriveBrandCode(value);
                    }
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'e.g. Coca-Cola',
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                _label('Brand Code *'),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('quick_add_brand_code_field'),
                  controller: _codeController,
                  maxLength: _maxCodeLength,
                  onChanged: (_) => _codeEditedManually = true,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'e.g. COCA_COLA',
                    helperText: 'Unique code for the brand',
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Status'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: const Key('quick_add_brand_status_field'),
                            initialValue: _status,
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
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                            decoration: const InputDecoration(isDense: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Sort Order'),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('quick_add_brand_sort_order_field'),
                            controller: _sortOrderController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                _label('Description (Optional)'),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('quick_add_brand_description_field'),
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: _maxDescriptionLength,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Optional brand description',
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: TenantAdminColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TenantAdminColors.bodyText,
                    side: const BorderSide(color: TenantAdminColors.border),
                    padding: const EdgeInsets.symmetric(
                      vertical: TenantAdminSpacing.md,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('quick_add_brand_save_button'),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text(
                    'Create Brand',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: TenantAdminSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: TenantAdminColors.bodyText,
        ),
      );
}

/// Slide-in drawer shell, mirroring the wizard's established
/// showGeneralDialog pattern (see EditVariantDrawer's _openEditVariantDrawer).
Future<void> openQuickAddBrandDrawer(
  BuildContext context, {
  String? prefillName,
  required ValueChanged<Brand> onCreated,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final drawerWidth = screenWidth < 440 ? screenWidth : 420.0;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close quick add brand',
    barrierColor: Colors.black54,
    useRootNavigator: false,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: slide,
          child: Material(
            color: TenantAdminColors.surface,
            elevation: 12,
            child: SizedBox(
              width: drawerWidth,
              height: double.infinity,
              child: QuickAddBrandDrawer(
                prefillName: prefillName,
                onCreated: onCreated,
              ),
            ),
          ),
        ),
      );
    },
  );
}
