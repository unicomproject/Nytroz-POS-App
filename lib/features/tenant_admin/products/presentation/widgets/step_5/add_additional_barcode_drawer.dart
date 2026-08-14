import 'package:flutter/material.dart';
import '../../../data/models/step5_barcode_dtos.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';

class AddAdditionalBarcodeDrawer extends StatefulWidget {
  final List<GeneratedVariantRow> activeVariants;
  final Function(Step5AdditionalBarcodeDto) onAdd;

  const AddAdditionalBarcodeDrawer({
    super.key,
    required this.activeVariants,
    required this.onAdd,
  });

  @override
  State<AddAdditionalBarcodeDrawer> createState() =>
      _AddAdditionalBarcodeDrawerState();
}

class _AddAdditionalBarcodeDrawerState
    extends State<AddAdditionalBarcodeDrawer> {
  late TextEditingController _barcodeController;
  final List<String> _barcodeTypes = ['EAN13', 'UPCA', 'CODE128', 'EAN8'];
  final _formKey = GlobalKey<FormState>();

  String? _barcodeType;
  String? _assignedToVariantId;
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (_formKey.currentState!.validate()) {
      widget.onAdd(Step5AdditionalBarcodeDto(
        barcode: _barcodeController.text.trim(),
        barcodeType: _barcodeType ?? _barcodeTypes.first,
        productVariantId: _assignedToVariantId,
        quantityPerScan: 1,
        isPrimary: _isPrimary,
        status: 'ACTIVE',
      ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create and assign a new barcode',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 24),
                    const Text('Barcode Number *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () {},
                          )),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Barcode Number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Barcode Type *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _barcodeType ?? _barcodeTypes.first,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: _barcodeTypes
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                           setState(() => _barcodeType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Assigned To *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _assignedToVariantId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Base Product')),
                        ...widget.activeVariants.map((v) => DropdownMenuItem(
                              value: v.productVariantId,
                              child: Text(v.displayLabel ?? v.combinationLabel),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _assignedToVariantId = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Set as Primary Barcode',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Switch(
                          value: _isPrimary,
                          onChanged: (val) => setState(() => _isPrimary = val),
                          activeColor: Colors.orange,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Add Additional Barcode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Barcode'),
          ),
        ],
      ),
    );
  }
}
