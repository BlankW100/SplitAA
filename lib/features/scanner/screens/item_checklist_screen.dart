import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_item.dart';
import '../../calculator/screens/fee_calculator_screen.dart';
import '../../split/screens/person_split_screen.dart';

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
        onConfirm: (name, price, qty) => setState(() {
          _items.add(ReceiptItem(
              id: _uuid.v4(), name: name, price: price, quantity: qty, isSelected: true));
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
        initialQuantity: item.quantity,
        onConfirm: (name, price, qty) => setState(() {
          _items[index].name = name;
          _items[index].price = price;
          _items[index].quantity = qty;
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
    _showSplitModeSheet();
  }

  void _showSplitModeSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('How do you want to split?',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Split evenly'),
              subtitle: const Text('One shared bill — everyone pays the same'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FeeCalculatorScreen(items: _selected)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_search_outlined),
              title: const Text('Split by item'),
              subtitle: const Text('Assign items per person — each gets their own bill & QR'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PersonSplitScreen(items: _selected)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null;

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: hasImage
                  ? Stack(
                      children: [
                        // Zoomable receipt photo behind the list.
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black,
                            child: InteractiveViewer(
                              maxScale: 5,
                              child: Image.file(
                                File(widget.imagePath!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        // Draggable sheet — slide down to see the photo,
                        // slide up to read the scanned list.
                        DraggableScrollableSheet(
                          initialChildSize: 0.55,
                          minChildSize: 0.12,
                          maxChildSize: 0.92,
                          snap: true,
                          snapSizes: const [0.12, 0.55, 0.92],
                          builder: (context, scrollController) =>
                              _buildSheet(scrollController),
                        ),
                      ],
                    )
                  : _buildSheet(null),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(ScrollController? scrollController) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = widget.imagePath != null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: hasImage
            ? const BorderRadius.vertical(top: Radius.circular(18))
            : null,
        boxShadow: hasImage
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)]
            : null,
      ),
      child: Column(
        children: [
          if (hasImage) ...[
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.drag_handle, size: 16, color: colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Drag down to view the receipt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: _items.isEmpty
                ? ListView(
                    controller: scrollController,
                    children: [
                      const SizedBox(height: 40),
                      const Center(child: Text('No items detected. Add them manually.')),
                      const SizedBox(height: 12),
                      Center(
                        child: FilledButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: scrollController,
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
                          subtitle: Text(item.quantity > 1
                              ? 'Qty ${item.quantity}  ·  RM ${item.price.toStringAsFixed(2)}'
                              : 'RM ${item.price.toStringAsFixed(2)}'),
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
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
    );
  }
}

// ── Shared add / edit dialog ──────────────────────────────────────────────────

class _ItemDialog extends StatefulWidget {
  final String? initialName;
  final double? initialPrice;
  final int initialQuantity;
  final void Function(String name, double price, int quantity) onConfirm;

  const _ItemDialog({
    this.initialName,
    this.initialPrice,
    this.initialQuantity = 1,
    required this.onConfirm,
  });

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
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
