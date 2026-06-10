import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/currency/currency_provider.dart';

/// A no-receipt manual splitter with two modes:
///  • Equal  — split one total evenly across N people.
///  • By item — add items, assign each to a person, see what each owes.
class QuickSplitScreen extends StatefulWidget {
  const QuickSplitScreen({super.key});

  @override
  State<QuickSplitScreen> createState() => _QuickSplitScreenState();
}

enum _Mode { equal, byItem }

class _QuickSplitScreenState extends State<QuickSplitScreen> {
  _Mode _mode = _Mode.equal;

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<CurrencyProvider>().displayCurrency.symbol;
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Split')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.equal, label: Text('Equal'), icon: Icon(Icons.balance)),
                ButtonSegment(value: _Mode.byItem, label: Text('By item'), icon: Icon(Icons.list_alt)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          Expanded(
            child: _mode == _Mode.equal
                ? _EqualSplit(symbol: symbol)
                : _ByItemSplit(symbol: symbol),
          ),
        ],
      ),
    );
  }
}

// ── Equal split ───────────────────────────────────────────────────────────────

class _EqualSplit extends StatefulWidget {
  final String symbol;
  const _EqualSplit({required this.symbol});

  @override
  State<_EqualSplit> createState() => _EqualSplitState();
}

class _EqualSplitState extends State<_EqualSplit> {
  final _totalCtrl = TextEditingController();
  int _people = 2;

  @override
  void dispose() {
    _totalCtrl.dispose();
    super.dispose();
  }

  double get _total => double.tryParse(_totalCtrl.text.trim()) ?? 0;
  double get _perPerson => _people > 0 ? _total / _people : 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _totalCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Total amount',
              prefixText: '${widget.symbol} ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Number of people', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _people > 1 ? () => setState(() => _people--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('$_people',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => setState(() => _people++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('Each person pays', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.symbol} ${_perPerson.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── By-item split ─────────────────────────────────────────────────────────────

class _Person {
  final String id;
  String name;
  _Person(this.id, this.name);
}

class _SplitItem {
  final String id;
  String name;
  double price;
  String? personId; // null = shared across everyone
  _SplitItem(this.id, this.name, this.price, this.personId);
}

class _ByItemSplit extends StatefulWidget {
  final String symbol;
  const _ByItemSplit({required this.symbol});

  @override
  State<_ByItemSplit> createState() => _ByItemSplitState();
}

class _ByItemSplitState extends State<_ByItemSplit> {
  static const _uuid = Uuid();
  final List<_Person> _people = [_Person('a', 'Person 1'), _Person('b', 'Person 2')];
  final List<_SplitItem> _items = [];

  Map<String, double> get _totals {
    final result = {for (final p in _people) p.id: 0.0};
    double shared = 0;
    for (final it in _items) {
      if (it.personId != null && result.containsKey(it.personId)) {
        result[it.personId!] = result[it.personId!]! + it.price;
      } else {
        shared += it.price;
      }
    }
    if (_people.isNotEmpty && shared > 0) {
      final each = shared / _people.length;
      for (final p in _people) {
        result[p.id] = result[p.id]! + each;
      }
    }
    return result;
  }

  void _addPerson() => setState(() {
        _people.add(_Person(_uuid.v4(), 'Person ${_people.length + 1}'));
      });

  void _addItem() {
    showDialog(
      context: context,
      builder: (_) => _ItemDialog(
        onConfirm: (name, price) =>
            setState(() => _items.add(_SplitItem(_uuid.v4(), name, price, null))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    return Column(
      children: [
        // People chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in _people)
                Chip(
                  label: Text(p.name),
                  onDeleted: _people.length > 1
                      ? () => setState(() {
                            _people.remove(p);
                            for (final it in _items) {
                              if (it.personId == p.id) it.personId = null;
                            }
                          })
                      : null,
                ),
              ActionChip(
                avatar: const Icon(Icons.person_add, size: 18),
                label: const Text('Add'),
                onPressed: _addPerson,
              ),
            ],
          ),
        ),
        const Divider(),
        // Items
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('Add items, then tap to assign each to a person.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final it = _items[i];
                    return Dismissible(
                      key: ValueKey(it.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) => setState(() => _items.removeAt(i)),
                      child: ListTile(
                        title: Text(it.name),
                        subtitle: Text('${widget.symbol} ${it.price.toStringAsFixed(2)}'),
                        trailing: DropdownButton<String?>(
                          value: it.personId,
                          hint: const Text('Shared'),
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Shared')),
                            for (final p in _people)
                              DropdownMenuItem(value: p.id, child: Text(p.name)),
                          ],
                          onChanged: (v) => setState(() => it.personId = v),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Per-person totals
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in _people)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name),
                      Text('${widget.symbol} ${totals[p.id]!.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Add-item dialog ───────────────────────────────────────────────────────────

class _ItemDialog extends StatefulWidget {
  final void Function(String name, double price) onConfirm;
  const _ItemDialog({required this.onConfirm});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

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
    return AlertDialog(
      title: const Text('Add Item'),
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
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
