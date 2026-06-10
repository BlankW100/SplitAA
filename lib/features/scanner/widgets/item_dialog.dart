import 'package:flutter/material.dart';

/// Shared add/edit dialog for a receipt item. [onConfirm] receives the name,
/// line total and quantity.
class ItemDialog extends StatefulWidget {
  final String? initialName;
  final double? initialPrice;
  final int initialQuantity;
  final void Function(String name, double price, int quantity) onConfirm;

  const ItemDialog({
    super.key,
    this.initialName,
    this.initialPrice,
    this.initialQuantity = 1,
    required this.onConfirm,
  });

  @override
  State<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<ItemDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initialPrice != null ? widget.initialPrice!.toStringAsFixed(2) : '',
    );
    _quantity = widget.initialQuantity;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty || price == null || price <= 0) return;
    widget.onConfirm(name, price, _quantity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Item' : 'Add Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Item name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _priceCtrl,
            decoration: const InputDecoration(
              labelText: 'Line total (RM)',
              prefixText: 'RM ',
              helperText: 'Total price for all units of this item',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Quantity'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Text('$_quantity', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
      ],
    );
  }
}
