import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_result.dart';
import '../services/receipt_generator.dart';
import '../../checklist/models/ledger_entry.dart';
import '../../checklist/providers/checklist_provider.dart';

class ReceiptResultScreen extends StatefulWidget {
  final ReceiptResult result;
  const ReceiptResultScreen({super.key, required this.result});

  @override
  State<ReceiptResultScreen> createState() => _ReceiptResultScreenState();
}

class _ReceiptResultScreenState extends State<ReceiptResultScreen> {
  static const _uuid = Uuid();
  Uint8List? _receiptImage;
  bool _isGenerating = true;
  bool _savedToLedger = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    final bytes = await ReceiptGenerator.generate(widget.result, context);
    if (mounted) setState(() { _receiptImage = bytes; _isGenerating = false; });
  }

  Future<void> _share() async {
    if (_receiptImage == null) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/splitaa_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(_receiptImage!);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'My split receipt — RM ${widget.result.total.toStringAsFixed(2)}',
      ),
    );
  }

  void _showQr() {
    final payload = widget.result.toQrPayload();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share via QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: payload, size: 220, version: QrVersions.auto),
            const SizedBox(height: 10),
            const Text(
              'Others can scan this with Splitaa\nto receive their copy of the receipt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _saveToLedger() async {
    final r = widget.result;
    final entry = LedgerEntry(
      id: _uuid.v4(),
      title: '${r.items.length} item(s) — ${_fmtDate(r.timestamp)}',
      totalAmount: r.total,
      isSettled: false,
      createdAt: r.timestamp,
      payload: r.toStorageJson(),
    );
    await context.read<ChecklistProvider>().addEntry(entry);
    if (mounted) {
      setState(() => _savedToLedger = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to ledger.')),
      );
    }
  }

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Back to home',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt image preview
            if (_isGenerating)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_receiptImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_receiptImage!),
              )
            else
              const Text('Could not generate receipt image.'),

            const SizedBox(height: 24),

            // Share + QR row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _receiptImage != null ? _share : null,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showQr,
                    icon: const Icon(Icons.qr_code_2_outlined),
                    label: const Text('QR Code'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Save to ledger
            FilledButton.icon(
              onPressed: _savedToLedger ? null : _saveToLedger,
              icon: Icon(_savedToLedger ? Icons.check : Icons.save_outlined),
              label: Text(_savedToLedger ? 'Saved to Ledger' : 'Save to Ledger'),
            ),

            const SizedBox(height: 24),

            // Summary breakdown (text fallback)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary', style: Theme.of(context).textTheme.titleSmall),
                    const Divider(),
                    ...widget.result.items.map(
                      (item) => _SummaryRow(
                          item.quantity > 1 ? '${item.quantity}× ${item.name}' : item.name,
                          'RM ${item.price.toStringAsFixed(2)}'),
                    ),
                    const Divider(),
                    _SummaryRow('Subtotal', 'RM ${widget.result.subtotal.toStringAsFixed(2)}', muted: true),
                    ...widget.result.fees.map((fee) {
                      final amount = fee.compute(widget.result.subtotal);
                      return _SummaryRow(
                        fee.label,
                        '${amount < 0 ? '-' : '+'}RM ${amount.abs().toStringAsFixed(2)}',
                        muted: true,
                        green: fee.isDiscount,
                      );
                    }),
                    const Divider(),
                    _SummaryRow(
                      'Total',
                      'RM ${widget.result.total.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Finish — return to the start of the flow.
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Done'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  final bool bold;
  final bool green;

  const _SummaryRow(this.label, this.value,
      {this.muted = false, this.bold = false, this.green = false});

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (green) color = Colors.green.shade700;
    if (muted) color ??= Colors.grey;

    final style = TextStyle(
      color: color,
      fontWeight: bold ? FontWeight.bold : null,
      fontSize: bold ? 15 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
