import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../scanner/models/receipt_item.dart';
import '../models/fee_item.dart';
import '../../receipt/screens/receipt_result_screen.dart';
import '../../receipt/models/receipt_result.dart';

class FeeCalculatorScreen extends StatefulWidget {
  final List<ReceiptItem> items;

  const FeeCalculatorScreen({super.key, required this.items});

  @override
  State<FeeCalculatorScreen> createState() => _FeeCalculatorScreenState();
}

class _FeeCalculatorScreenState extends State<FeeCalculatorScreen> {
  static const _uuid = Uuid();
  late List<FeeItem> _fees;

  @override
  void initState() {
    super.initState();
    _fees = [
      FeeItem(id: _uuid.v4(), label: 'Tax / GST', isPercentage: true),
      FeeItem(id: _uuid.v4(), label: 'Service Charge', isPercentage: true),
      FeeItem(id: _uuid.v4(), label: 'Discount', isPercentage: true, isDiscount: true),
    ];
  }

  double get _subtotal => widget.items.fold(0, (s, i) => s + i.price);
  double get _feesTotal => _fees.fold(0.0, (s, f) => s + f.compute(_subtotal));
  double get _total => _subtotal + _feesTotal;

  void _showAddFeeDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddFeeDialog(
        onAdd: (label, isPercentage, isDiscount) => setState(() {
          _fees.add(FeeItem(
            id: _uuid.v4(),
            label: label,
            isEnabled: true,
            isPercentage: isPercentage,
            isDiscount: isDiscount,
          ));
        }),
      ),
    );
  }

  void _confirm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptResultScreen(
          result: ReceiptResult(
            items: widget.items,
            fees: _fees.where((f) => f.isEnabled).toList(),
            subtotal: _subtotal,
            total: _total,
            timestamp: DateTime.now(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fees & Discounts')),
      body: Column(
        children: [
          // Items summary card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Items', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    ...widget.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                            Text('RM ${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          'RM ${_subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fee rows
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Row(
                  children: [
                    Text('Additional Fees / Discounts',
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showAddFeeDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Custom'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ..._fees.asMap().entries.map((e) => _FeeRow(
                      key: ValueKey(e.value.id),
                      fee: e.value,
                      onToggle: (val) => setState(() => e.value.isEnabled = val),
                      onValueChanged: (val) => setState(() => e.value.value = val),
                      onTypeChanged: (isPercent) =>
                          setState(() => e.value.isPercentage = isPercent),
                    )),
              ],
            ),
          ),

          // Total + confirm
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Column(
              children: [
                // Fee breakdown lines
                ..._fees.where((f) => f.isEnabled && f.value > 0).map((f) {
                  final amount = f.compute(_subtotal);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${f.label} (${f.isPercentage ? '${f.value}%' : 'RM ${f.value.toStringAsFixed(2)}'})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${amount < 0 ? '-' : '+'}RM ${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: amount < 0 ? Colors.green.shade700 : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(
                      'RM ${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _confirm,
                    child: const Text('Confirm & Generate Receipt'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fee row widget ────────────────────────────────────────────────────────────

class _FeeRow extends StatefulWidget {
  final FeeItem fee;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onValueChanged;
  final ValueChanged<bool> onTypeChanged;

  const _FeeRow({
    super.key,
    required this.fee,
    required this.onToggle,
    required this.onValueChanged,
    required this.onTypeChanged,
  });

  @override
  State<_FeeRow> createState() => _FeeRowState();
}

class _FeeRowState extends State<_FeeRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.fee.value > 0 ? widget.fee.value.toString() : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: widget.fee.isEnabled,
              onChanged: (val) => widget.onToggle(val ?? false),
            ),
            Expanded(
              child: Text(
                widget.fee.label,
                style: TextStyle(
                  color: widget.fee.isDiscount ? Colors.green.shade700 : null,
                ),
              ),
            ),
            if (widget.fee.isEnabled) ...[
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => widget.onValueChanged(double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 4),
              DropdownButton<bool>(
                value: widget.fee.isPercentage,
                isDense: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: true, child: Text('%')),
                  DropdownMenuItem(value: false, child: Text('RM')),
                ],
                onChanged: (val) => widget.onTypeChanged(val ?? true),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Add custom fee dialog ─────────────────────────────────────────────────────

class _AddFeeDialog extends StatefulWidget {
  final void Function(String label, bool isPercentage, bool isDiscount) onAdd;
  const _AddFeeDialog({required this.onAdd});

  @override
  State<_AddFeeDialog> createState() => _AddFeeDialogState();
}

class _AddFeeDialogState extends State<_AddFeeDialog> {
  final _ctrl = TextEditingController();
  bool _isPercentage = true;
  bool _isDiscount = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Fee'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(labelText: 'Label (e.g. "SST 8%")'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Unit: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Percentage %'),
                selected: _isPercentage,
                onSelected: (_) => setState(() => _isPercentage = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Fixed RM'),
                selected: !_isPercentage,
                onSelected: (_) => setState(() => _isPercentage = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _isDiscount,
            onChanged: (val) => setState(() => _isDiscount = val ?? false),
            title: const Text('This is a discount'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final label = _ctrl.text.trim();
            if (label.isEmpty) return;
            widget.onAdd(label, _isPercentage, _isDiscount);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
