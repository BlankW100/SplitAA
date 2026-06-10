import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/person_bill.dart';
import '../../calculator/models/fee_item.dart';
import '../../calculator/widgets/fee_editor.dart';
import '../../receipt/models/receipt_result.dart';
import 'multi_receipt_result_screen.dart';

/// Shared tax/discount editor applied to every person's bill. Each fee is
/// computed against that person's own subtotal, then we generate one receipt
/// per person.
class SplitCheckoutScreen extends StatefulWidget {
  final List<PersonBill> people;
  const SplitCheckoutScreen({super.key, required this.people});

  @override
  State<SplitCheckoutScreen> createState() => _SplitCheckoutScreenState();
}

class _SplitCheckoutScreenState extends State<SplitCheckoutScreen> {
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

  List<FeeItem> get _enabledFees =>
      _fees.where((f) => f.isEnabled && f.value > 0).toList();

  double _feesFor(double subtotal) =>
      _fees.fold(0.0, (s, f) => s + f.compute(subtotal));

  double _totalFor(PersonBill p) => p.subtotal + _feesFor(p.subtotal);

  double get _grandTotal =>
      widget.people.fold(0.0, (s, p) => s + _totalFor(p));

  void _showAddFeeDialog() {
    showDialog(
      context: context,
      builder: (_) => AddFeeDialog(
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

  void _generate() {
    final now = DateTime.now();
    final results = widget.people.map((p) {
      // Clone the enabled fees per person so each receipt is self-contained.
      final fees = _enabledFees
          .map((f) => FeeItem(
              id: _uuid.v4(),
              label: f.label,
              isEnabled: true,
              isPercentage: f.isPercentage,
              value: f.value,
              isDiscount: f.isDiscount))
          .toList();
      return ReceiptResult(
        items: p.items,
        fees: fees,
        subtotal: p.subtotal,
        total: _totalFor(p),
        timestamp: now,
        payerName: p.name,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MultiReceiptResultScreen(results: results)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Per-person preview
                  Text('${widget.people.length} bill(s)', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  ...widget.people.map((p) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(p.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Text('RM ${_totalFor(p).toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...p.items.map((i) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 1),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            i.quantity > 1 ? '${i.quantity}× ${i.name}' : i.name,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                        Text('RM ${i.price.toStringAsFixed(2)}',
                                            style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  )),
                              if (_enabledFees.isNotEmpty) ...[
                                const Divider(height: 12),
                                Text('Subtotal RM ${p.subtotal.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ],
                          ),
                        ),
                      )),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Tax / Discount for every bill',
                          style: theme.textTheme.labelLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showAddFeeDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Custom'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._fees.map((fee) => FeeRow(
                        key: ValueKey(fee.id),
                        fee: fee,
                        onToggle: (val) => setState(() => fee.isEnabled = val),
                        onValueChanged: (val) => setState(() => fee.value = val),
                        onTypeChanged: (isPercent) =>
                            setState(() => fee.isPercentage = isPercent),
                      )),
                  const SizedBox(height: 4),
                  Text(
                    'Each fee is calculated on that person\'s own subtotal.',
                    style: theme.textTheme.bodySmall,
                  ),
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
                      const Text('Grand total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('RM ${_grandTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Generate Receipts & QRs'),
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
