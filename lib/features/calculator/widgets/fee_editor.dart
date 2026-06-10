import 'package:flutter/material.dart';
import '../models/fee_item.dart';

/// A single editable fee row: enable checkbox, label, value field and a % / RM
/// unit toggle. Keeps its own controller so typing doesn't reset on rebuild.
class FeeRow extends StatefulWidget {
  final FeeItem fee;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onValueChanged;
  final ValueChanged<bool> onTypeChanged;

  const FeeRow({
    super.key,
    required this.fee,
    required this.onToggle,
    required this.onValueChanged,
    required this.onTypeChanged,
  });

  @override
  State<FeeRow> createState() => _FeeRowState();
}

class _FeeRowState extends State<FeeRow> {
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

/// Dialog for adding a custom fee/discount.
class AddFeeDialog extends StatefulWidget {
  final void Function(String label, bool isPercentage, bool isDiscount) onAdd;
  const AddFeeDialog({super.key, required this.onAdd});

  @override
  State<AddFeeDialog> createState() => _AddFeeDialogState();
}

class _AddFeeDialogState extends State<AddFeeDialog> {
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
