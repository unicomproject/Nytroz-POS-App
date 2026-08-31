import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../application/tax_management_controller.dart';
import '../domain/tax_aggregate.dart';

class TaxManagementPage extends ConsumerStatefulWidget {
  const TaxManagementPage({super.key});

  @override
  ConsumerState<TaxManagementPage> createState() => _TaxManagementPageState();
}

class _TaxManagementPageState extends ConsumerState<TaxManagementPage> {
  bool _showForm = false;
  bool _isViewOnly = false;
  String? _selectedTaxId;

  void _openForm({String? taxId, bool isViewOnly = false}) {
    setState(() {
      _showForm = true;
      _isViewOnly = isViewOnly;
      _selectedTaxId = taxId;
    });
    if (taxId != null && !isViewOnly) {
      ref.read(taxManagementControllerProvider.notifier).startEditing(taxId);
    } else {
      ref.read(taxManagementControllerProvider.notifier).cancelEditing();
    }
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _isViewOnly = false;
      _selectedTaxId = null;
    });
    ref.read(taxManagementControllerProvider.notifier).cancelEditing();
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Tax Management',
        subtitle: 'Manage taxes and tax rates for your products.',
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Tax Management',
        subtitle: 'Manage taxes and tax rates for your products.',
        child: TenantAdminErrorState(
          title: 'Unable to load access rules',
          message: 'Please try again.',
          onRetry: () => ref.refresh(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        if (!access.canAccessProductListPage()) {
          return const TenantAdminPageScaffold(
            title: 'No access to Tax',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view taxes.',
              icon: Icons.account_balance_outlined,
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: 'Tax Management',
          subtitle: 'Manage taxes and tax rates for your products.',
          scrollable: false,
          actions: [
            TenantAdminPrimaryButton(
              label: 'Add Tax',
              icon: Icons.add,
              backgroundColor: TenantAdminColors.posHomeAccentOrange,
              onPressed: () => _openForm(),
            ),
          ],
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TaxTableSection(
                  onView: (id) => _openForm(taxId: id, isViewOnly: true),
                  onEdit: (id) => _openForm(taxId: id),
                ),
              ),
              if (_showForm) ...[
                const SizedBox(width: TenantAdminSpacing.lg),
                Container(
                  width: 420,
                  decoration: BoxDecoration(
                    color: TenantAdminColors.surface,
                    border: Border.all(color: TenantAdminColors.border),
                    borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                    child: _TaxFormSection(
                      taxId: _selectedTaxId,
                      isViewOnly: _isViewOnly,
                      onClose: _closeForm,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TaxFormSection extends ConsumerStatefulWidget {
  const _TaxFormSection({
    this.taxId,
    this.isViewOnly = false,
    required this.onClose,
  });

  final String? taxId;
  final bool isViewOnly;
  final VoidCallback onClose;

  @override
  ConsumerState<_TaxFormSection> createState() => _TaxFormSectionState();
}

class _TaxFormSectionState extends ConsumerState<_TaxFormSection> {
  final _formKey = GlobalKey<FormState>();
  final _taxNameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _taxPercentageController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _taxType = 'PERCENTAGE';
  String _status = 'ACTIVE';

  String? _lastPopulatedId;

  @override
  void dispose() {
    _taxNameController.dispose();
    _taxCodeController.dispose();
    _taxPercentageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TaxFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.taxId != oldWidget.taxId) {
      _lastPopulatedId = null;
    }
  }

  void _populateForm(TaxAggregate tax) {
    _taxNameController.text = tax.taxName;
    _taxCodeController.text = tax.taxCode;
    _taxPercentageController.text = tax.taxPercentage.toString();
    _descriptionController.text = tax.description ?? '';
    _taxType = tax.taxType;
    _status = tax.status;
  }

  void _resetForm() {
    _taxNameController.clear();
    _taxCodeController.clear();
    _taxPercentageController.clear();
    _descriptionController.clear();
    setState(() {
      _taxType = 'PERCENTAGE';
      _status = 'ACTIVE';
    });
  }

  void _submit() {
    if (widget.isViewOnly) {
      widget.onClose();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final input = TaxAggregateUpsertInput(
      taxName: _taxNameController.text,
      taxCode: _taxCodeController.text,
      taxType: _taxType,
      taxPercentage: double.tryParse(_taxPercentageController.text) ?? 0.0,
      description: _descriptionController.text,
      status: _status,
    );

    final isEditing = ref.read(taxManagementControllerProvider).isEditing;

    ref
        .read(taxManagementControllerProvider.notifier)
        .submitTax(input)
        .then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Tax updated successfully.'
              : 'Tax created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onClose();
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save tax. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taxManagementControllerProvider);
    final taxes = ref.watch(taxListProvider).valueOrNull?.items ?? [];

    if (widget.taxId != null && _lastPopulatedId != widget.taxId) {
      final tax = taxes.firstWhere((t) => t.id == widget.taxId,
          orElse: () => taxes.first);
      _populateForm(tax);
      _lastPopulatedId = widget.taxId;
    } else if (widget.taxId == null && _lastPopulatedId != null) {
      _resetForm();
      _lastPopulatedId = null;
    }

    final title = widget.isViewOnly
        ? 'View Tax'
        : (state.isEditing ? 'Edit Tax' : 'Create Tax');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.xl,
              vertical: TenantAdminSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon:
                    const Icon(Icons.close, color: TenantAdminColors.bodyText),
                onPressed: widget.onClose,
                splashRadius: 20,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildNameField(),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _buildCodeField(state.isEditing || widget.isViewOnly),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _buildTypeField(),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _buildRateField(),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _buildDescField(),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _buildStatusField(),
                  const SizedBox(height: TenantAdminSpacing.xxl),
                  if (!widget.isViewOnly)
                    Row(
                      children: [
                        Expanded(
                          child: TenantAdminSecondaryButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () {
                                    if (state.isEditing) {
                                      widget.onClose();
                                    } else {
                                      _resetForm();
                                    }
                                  },
                            label: state.isEditing ? 'Cancel' : 'Reset',
                          ),
                        ),
                        const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(
                          child: TenantAdminPrimaryButton(
                            label:
                                state.isEditing ? 'Save Changes' : 'Create Tax',
                            loading: state.isSubmitting,
                            onPressed: _submit,
                            backgroundColor:
                                TenantAdminColors.posHomeAccentOrange,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _taxNameController,
      decoration: const InputDecoration(
          labelText: 'Tax Name *', border: OutlineInputBorder()),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      enabled: !widget.isViewOnly,
    );
  }

  Widget _buildCodeField(bool disabled) {
    return TextFormField(
      controller: _taxCodeController,
      decoration: InputDecoration(
        labelText: 'Tax Code *',
        border: const OutlineInputBorder(),
        fillColor: disabled ? Colors.grey.shade100 : null,
        filled: disabled,
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      enabled: !disabled,
      style: TextStyle(color: disabled ? Colors.black54 : Colors.black87),
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: _taxType,
      decoration: const InputDecoration(
          labelText: 'Tax Type *', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage')),
        DropdownMenuItem(value: 'FIXED', child: Text('Fixed Amount')),
      ],
      onChanged:
          widget.isViewOnly ? null : (val) => setState(() => _taxType = val!),
    );
  }

  Widget _buildRateField() {
    final label =
        _taxType == 'PERCENTAGE' ? 'Tax Rate (%) *' : 'Tax Amount (LKR) *';
    return TextFormField(
      controller: _taxPercentageController,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Required';
        final num = double.tryParse(val);
        if (num == null || num < 0 || (_taxType == 'PERCENTAGE' && num > 100))
          return 'Invalid value';
        return null;
      },
      enabled: !widget.isViewOnly,
    );
  }

  Widget _buildDescField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
          labelText: 'Description', border: OutlineInputBorder()),
      enabled: !widget.isViewOnly,
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: _status,
      decoration: const InputDecoration(
          labelText: 'Status *', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
      ],
      onChanged:
          widget.isViewOnly ? null : (val) => setState(() => _status = val!),
    );
  }
}

class _TaxTableSection extends ConsumerStatefulWidget {
  const _TaxTableSection({
    required this.onView,
    required this.onEdit,
  });

  final ValueChanged<String> onView;
  final ValueChanged<String> onEdit;

  @override
  ConsumerState<_TaxTableSection> createState() => _TaxTableSectionState();
}

class _TaxTableSectionState extends ConsumerState<_TaxTableSection> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  int _currentPage = 1;
  static const int _rowsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final taxesState = ref.watch(taxListProvider);
    final editingState = ref.watch(taxManagementControllerProvider);

    return taxesState.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load taxes',
        message: 'Please try again.',
        onRetry: () => ref.refresh(taxListProvider),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return const TenantAdminEmptyState(
            title: 'No taxes yet',
            message: 'Create your first tax to get started.',
            icon: Icons.receipt_long_outlined,
          );
        }

        final filteredTaxes = result.items.where((tax) {
          final matchesSearch = tax.taxName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              tax.taxCode.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesStatus = _statusFilter == 'All' ||
              (_statusFilter == 'Active' && tax.status == 'ACTIVE') ||
              (_statusFilter == 'Inactive' && tax.status != 'ACTIVE');
          return matchesSearch && matchesStatus;
        }).toList();

        final totalPages = (filteredTaxes.length / _rowsPerPage).ceil();
        final maxPage = totalPages > 0 ? totalPages : 1;
        if (_currentPage > maxPage) _currentPage = maxPage;

        final startIndex = (_currentPage - 1) * _rowsPerPage;
        final endIndex =
            (startIndex + _rowsPerPage).clamp(0, filteredTaxes.length);
        final paginatedTaxes = filteredTaxes.sublist(startIndex, endIndex);

        return Column(
          children: [
            _buildToolbar(),
            const SizedBox(height: TenantAdminSpacing.md),
            Expanded(
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                  side: const BorderSide(color: TenantAdminColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: false,
                              dataRowMinHeight: 64,
                              dataRowMaxHeight: 72,
                              headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF8F8F8)),
                              headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                              columns: const [
                                DataColumn(label: Text('Tax Name')),
                                DataColumn(label: Text('Tax Code')),
                                DataColumn(label: Text('Tax Type')),
                                DataColumn(label: Text('Rate / Amount')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Updated On')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: paginatedTaxes.map((tax) {
                                final isEditingRow =
                                    editingState.editingTaxId == tax.id;
                                return DataRow(
                                  color: WidgetStateProperty.all(
                                    isEditingRow
                                        ? const Color(0xFFFFF4EC)
                                        : null,
                                  ),
                                  onSelectChanged: (_) => widget.onView(tax.id),
                                  cells: [
                                    DataCell(Text(tax.taxName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500))),
                                    DataCell(Text(tax.taxCode)),
                                    DataCell(Text(tax.taxType == 'PERCENTAGE'
                                        ? 'Percentage'
                                        : 'Fixed Amount')),
                                    DataCell(Text(
                                      tax.taxType == 'PERCENTAGE'
                                          ? '${tax.taxPercentage.toStringAsFixed(tax.taxPercentage.truncateToDouble() == tax.taxPercentage ? 0 : 2)}%'
                                          : 'LKR ${tax.taxPercentage.toStringAsFixed(2)}',
                                    )),
                                    DataCell(_buildStatusBadge(tax.status)),
                                    DataCell(const Text(
                                        '-')), // Placeholder as DTO doesn't have Updated On
                                    DataCell(
                                      _TaxActionColumn(
                                        onEdit: () => widget.onEdit(tax.id),
                                        onDelete: () =>
                                            _confirmDelete(context, ref, tax),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildPagination(filteredTaxes.length, totalPages),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: TenantAdminContentTokens.formFieldHeight,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search taxes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => setState(() {
                _searchQuery = val;
                _currentPage = 1;
              }),
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: TenantAdminContentTokens.formFieldHeight,
            child: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _statusFilter,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('Status: All')),
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (val) => setState(() {
                _statusFilter = val!;
                _currentPage = 1;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();

    final startIndex = (_currentPage - 1) * _rowsPerPage + 1;
    final endIndex = (startIndex + _rowsPerPage - 1).clamp(1, totalItems);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg, vertical: TenantAdminSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startIndex–$endIndex of $totalItems',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                child: const Text('Previous'),
              ),
              for (int i = 1; i <= totalPages; i++)
                InkWell(
                  onTap: () => setState(() => _currentPage = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? TenantAdminColors.posHomeAccentOrange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color:
                            _currentPage == i ? Colors.white : Colors.black87,
                        fontWeight: _currentPage == i
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              TextButton(
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TaxAggregate tax) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tax?'),
        content: Text(
            'Are you sure you want to delete "${tax.taxName}"?\n\nThis action may affect products currently using this tax.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: TenantAdminColors.danger,
                foregroundColor: Colors.white),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              ref
                  .read(taxManagementControllerProvider.notifier)
                  .deleteTax(tax.id)
                  .then((_) {
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Tax deleted successfully.'),
                      behavior: SnackBarBehavior.floating),
                );
              }).catchError((e) {
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Unable to delete tax. Please try again.'),
                      behavior: SnackBarBehavior.floating),
                );
              });
            },
            child: const Text('Delete Tax'),
          ),
        ],
      ),
    );
  }
}

class _TaxActionColumn extends StatelessWidget {
  const _TaxActionColumn({
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return TenantAdminOverflowMenu(
      actions: [
        TenantAdminOverflowAction(
          id: 'edit',
          icon: Icons.edit_outlined,
          label: 'Edit',
          onSelected: onEdit,
        ),
        TenantAdminOverflowAction(
          id: 'delete',
          icon: Icons.delete_outline,
          label: 'Delete',
          destructive: true,
          onSelected: onDelete,
        ),
      ],
    );
  }
}
