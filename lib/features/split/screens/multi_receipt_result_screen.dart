import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../receipt/models/receipt_result.dart';
import '../../receipt/services/receipt_generator.dart';
import '../../checklist/models/ledger_entry.dart';
import '../../checklist/providers/checklist_provider.dart';

class MultiReceiptResultScreen extends StatefulWidget {
  final List<ReceiptResult> results;
  const MultiReceiptResultScreen({super.key, required this.results});

  @override
  State<MultiReceiptResultScreen> createState() => _MultiReceiptResultScreenState();
}

class _MultiReceiptResultScreenState extends State<MultiReceiptResultScreen> {
  static const _uuid = Uuid();
  bool _savedAll = false;

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<void> _saveAll() async {
    final provider = context.read<ChecklistProvider>();
    for (final r in widget.results) {
      final entry = LedgerEntry(
        id: _uuid.v4(),
        title: '${r.payerName ?? 'Bill'} — ${_fmtDate(r.timestamp)}',
        totalAmount: r.total,
        debtorIdentifier: r.payerName,
        isSettled: false,
        createdAt: r.timestamp,
        payload: r.toStorageJson(),
      );
      await provider.addEntry(entry);
    }
    if (mounted) {
      setState(() => _savedAll = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.results.length} bill(s) saved to ledger.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Back to home',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final r in widget.results)
                    _PersonReceiptCard(result: r),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                    top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _savedAll ? null : _saveAll,
                      icon: Icon(_savedAll ? Icons.check : Icons.save_outlined),
                      label: Text(_savedAll ? 'Saved to Ledger' : 'Save all to Ledger'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Done'),
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

class _PersonReceiptCard extends StatefulWidget {
  final ReceiptResult result;
  const _PersonReceiptCard({required this.result});

  @override
  State<_PersonReceiptCard> createState() => _PersonReceiptCardState();
}

class _PersonReceiptCardState extends State<_PersonReceiptCard> {
  Uint8List? _image;
  bool _generating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    final bytes = await ReceiptGenerator.generate(
      widget.result,
      context,
      payerName: widget.result.payerName,
    );
    if (mounted) setState(() { _image = bytes; _generating = false; });
  }

  Future<void> _share() async {
    if (_image == null) return;
    final dir = await getTemporaryDirectory();
    final name = (widget.result.payerName ?? 'bill').replaceAll(RegExp(r'\s+'), '_');
    final path = '${dir.path}/splitaa_${name}_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(_image!);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: '${widget.result.payerName ?? ''} — RM ${widget.result.total.toStringAsFixed(2)}',
      ),
    );
  }

  void _showQr() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${widget.result.payerName ?? 'Bill'} — QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
                data: widget.result.toQrPayload(), size: 220, version: QrVersions.auto),
            const SizedBox(height: 10),
            const Text(
              'Scan with Splitaa to receive this bill.',
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.result.payerName ?? 'Bill',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text('RM ${widget.result.total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 10),
            if (_generating)
              const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
            else if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_image!),
              )
            else
              const Text('Could not generate receipt.'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _image != null ? _share : null,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showQr,
                    icon: const Icon(Icons.qr_code_2_outlined, size: 18),
                    label: const Text('QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
