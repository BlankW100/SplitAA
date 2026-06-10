import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../scanner/models/receipt_item.dart';
import '../models/person_bill.dart';
import 'split_checkout_screen.dart';

/// Build each person's plate by tapping items from the shared pool. Assigning
/// an item moves one unit to the current person; when an item's quantity hits
/// zero it leaves the pool. Repeat per person until the pool is empty.
class PersonSplitScreen extends StatefulWidget {
  final List<ReceiptItem> items;
  const PersonSplitScreen({super.key, required this.items});

  @override
  State<PersonSplitScreen> createState() => _PersonSplitScreenState();
}

class _PersonSplitScreenState extends State<PersonSplitScreen> {
  static const _uuid = Uuid();
  late List<ReceiptItem> _pool;
  final List<PersonBill> _people = [];
  late PersonBill _current;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pool = widget.items
        .map((i) => ReceiptItem(
            id: i.id, name: i.name, price: i.price, quantity: i.quantity))
        .toList();
    _current = PersonBill(id: _uuid.v4(), name: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _poolEmpty => _pool.isEmpty;

  void _assign(String id) => setState(() => SplitOps.assignUnit(_pool, _current, id));
  void _return(String id) => setState(() => SplitOps.returnUnit(_pool, _current, id));

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  bool _finalizeCurrent() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Enter this person\'s name first.');
      return false;
    }
    if (_current.items.isEmpty) {
      _snack('Assign at least one item to $name.');
      return false;
    }
    _current.name = name;
    return true;
  }

  void _nextPerson() {
    if (!_finalizeCurrent()) return;
    setState(() {
      _people.add(_current);
      _current = PersonBill(id: _uuid.v4(), name: '');
      _nameCtrl.clear();
    });
  }

  void _finish() {
    if (!_finalizeCurrent()) return;
    final all = [..._people, _current];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SplitCheckoutScreen(people: all)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Split — Person ${_people.length + 1}')),
      body: SafeArea(
        child: Column(
          children: [
            // Already-assigned people summary
            if (_people.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _people
                      .map((p) => Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.person, size: 16),
                            label: Text('${p.name}  ·  RM ${p.subtotal.toStringAsFixed(2)}'),
                          ))
                      .toList(),
                ),
              ),

            // Name field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Who is this bill for?',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  // Remaining pool
                  Text('Tap to add  ·  ${_pool.length} item(s) left',
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  if (_poolEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('All items assigned 🎉',
                          style: TextStyle(color: colorScheme.primary)),
                    )
                  else
                    ..._pool.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text('${item.quantity}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            title: Text(item.name),
                            subtitle: Text('RM ${item.price.toStringAsFixed(2)} left'),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () => _assign(item.id),
                          ),
                        )),

                  const SizedBox(height: 12),
                  const Divider(),
                  Text("Assigned to this person", style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  if (_current.items.isEmpty)
                    Text('Nothing yet — tap items above.',
                        style: TextStyle(color: colorScheme.outline))
                  else
                    ..._current.items.map((item) => ListTile(
                          dense: true,
                          leading: item.quantity > 1
                              ? CircleAvatar(
                                  radius: 14,
                                  backgroundColor: colorScheme.secondaryContainer,
                                  child: Text('${item.quantity}',
                                      style: const TextStyle(fontSize: 12)))
                              : const Icon(Icons.check),
                          title: Text(item.name),
                          subtitle: Text('RM ${item.price.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Return to pool',
                            onPressed: () => _return(item.id),
                          ),
                        )),
                ],
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('This person:', style: theme.textTheme.bodyMedium),
                      Text('RM ${_current.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _poolEmpty ? null : _nextPerson,
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('Next person'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _poolEmpty ? _finish : null,
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                  if (!_poolEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Assign all items to enable checkout.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
