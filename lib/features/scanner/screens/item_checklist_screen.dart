import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_item.dart';
import '../../calculator/screens/fee_calculator_screen.dart';

class ItemChecklistScreen extends StatefulWidget {
  final List<ReceiptItem> parsedItems;
  final String? imagePath;

  const ItemChecklistScreen({
    super.key,
    required this.parsedItems,
    this.imagePath,
  });

  @override
  State<ItemChecklistScreen> createState() => _ItemChecklistScreenState();
}

class _ItemChecklistScreenState extends State<ItemChecklistScreen> {
  static const _uuid = Uuid();
  late List<ReceiptItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.parsedItems);
    for (final item in _items) {
      item.isSelected = true;
    }
  }

  List<ReceiptItem> get _selected => _items.where((i) => i.isSelected).toList();
  double get _subtotal => _selected.fold(0, (s, i) => s + i.price);

  void _toggle(String id) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) _items[idx].isSelected = !_items[idx].isSelected;
    });
  }

  void _delete(int index) => setState(() => _items.removeAt(index));

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _ItemDialog(
        onConfirm: (name, price) => setState(() {
          _items.add(ReceiptItem(id: _uuid.v4(), name: name, price: price, isSelected: true));
        }),
      ),
    );
  }

  void _showEditDialog(int index) {
    final item = _items[index];
    showDialog(
      context: context,
      builder: (_) => _ItemDialog(
        initialName: item.name,
        initialPrice: item.price,
        onConfirm: (name, price) => setState(() {
          _items[index].name = name;
          _items[index].price = price;
        }),
      ),
    );
  }

  void _proceed() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to continue.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FeeCalculatorScreen(items: _selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add item manually',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thumbnail of the receipt photo
          if (widget.imagePath != null)
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Image.file(
                File(widget.imagePath!),
                fit: BoxFit.cover,
              ),
            ),

          // Item list
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No items detected. Add them manually.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete_outline, color: colorScheme.onError),
                        ),
                        onDismissed: (_) => _delete(index),
                        child: CheckboxListTile(
                          value: item.isSelected,
                          onChanged: (_) => _toggle(item.id),
                          title: Text(item.name),
                          subtitle: Text('RM ${item.price.toStringAsFixed(2)}'),
                          secondary: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showEditDialog(index),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selected.length} of ${_items.length} selected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Subtotal: RM ${_subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _proceed,
                  child: const Text('Next: Fees'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared add / edit dialog ──────────────────────────────────────────────────

class _ItemDialog extends StatefulWidget {
  final String? initialName;
  final double? initialPrice;
  final void Function(String name, double price) onConfirm;

  const _ItemDialog({this.initialName, this.initialPrice, required this.onConfirm});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initialPrice != null ? widget.initialPrice!.toStringAsFixed(2) : '',
    );
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
    widget.onConfirm(name, price);
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
            decoration: const InputDecoration(labelText: 'Price (RM)', prefixText: 'RM '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
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
