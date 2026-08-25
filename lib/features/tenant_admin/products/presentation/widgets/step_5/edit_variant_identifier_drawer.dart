import 'package:flutter/material.dart';
import '../../../data/models/step5_barcode_dtos.dart';

class EditVariantIdentifierDrawer extends StatefulWidget {
  final Step5VariantIdentifierDto variantDto;
  final String displayLabel;
  final ValueChanged<Step5VariantIdentifierDto> onUpdate;

  const EditVariantIdentifierDrawer({
    super.key,
    required this.variantDto,
    required this.displayLabel,
    required this.onUpdate,
  });

  @override
  State<EditVariantIdentifierDrawer> createState() =>
      _EditVariantIdentifierDrawerState();
}

class _EditVariantIdentifierDrawerState
    extends State<EditVariantIdentifierDrawer> {
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.variantDto.sku);
    _barcodeController = TextEditingController(text: widget.variantDto.barcode);
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (_formKey.currentState!.validate()) {
      widget.onUpdate(Step5VariantIdentifierDto(
        productVariantId: widget.variantDto.productVariantId,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
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
                    const Text('Variant',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: widget.displayLabel,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('SKU *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (val) {
                         if (val == null || val.trim().isEmpty) {
                            return 'SKU is required';
                         }
                         return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Barcode *',
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
                            onPressed: () {
                              // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanner opened')));
                              // Hardware scanner integration goes here.
                            },
                          )),
                      validator: (val) {
                         if (val == null || val.trim().isEmpty) {
                            return 'Barcode is required';
                         }
                         return null;
                      },
                    ),
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
          Expanded(
            child: Text(
              'Edit Variant (${widget.displayLabel})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
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
            onPressed: _onUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
