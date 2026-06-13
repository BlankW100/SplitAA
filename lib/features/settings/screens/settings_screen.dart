import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/currency/currency.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/services/crop_service.dart';
import '../../../core/services/notification_service.dart';
import '../../checklist/providers/checklist_provider.dart';
import '../services/payment_profile_service.dart';
import '../services/qr_validator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Payment'),
          const _PaymentQrTile(),
          const Divider(),
          const _SectionHeader('Notifications'),
          const _NotificationsTile(),
          const Divider(),
          const _SectionHeader('Currency'),
          const _CurrencyTile(),
          const Divider(),
          const _SectionHeader('Backup'),
          const _BackupTiles(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          )),
    );
  }
}

class _PaymentQrTile extends StatefulWidget {
  const _PaymentQrTile();

  @override
  State<_PaymentQrTile> createState() => _PaymentQrTileState();
}

class _PaymentQrTileState extends State<_PaymentQrTile> {
  String? _qrPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await PaymentProfileService.getQrPath();
    if (mounted) setState(() { _qrPath = path; _loading = false; });
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Let the user crop to isolate the QR before we validate.
    final cropped = await CropService.cropQr(picked.path);
    if (cropped == null) return; // user cancelled crop

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await QrValidator.validate(cropped);

    if (!mounted) return;
    setState(() => _loading = false);

    // Show validation result and let user decide whether to save.
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isOk ? Icons.check_circle_outline : Icons.warning_amber_outlined,
              color: result.isOk ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(result.isOk ? 'QR Detected' : 'QR Warning')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (result.previewData != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(File(cropped), height: 120, fit: BoxFit.contain),
              ),
              const SizedBox(height: 6),
              Text(
                'Content: ${result.previewData}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(result.isOk ? 'Save' : 'Save anyway'),
          ),
        ],
      ),
    );

    if (save != true || !mounted) return;
    final saved = await PaymentProfileService.setQr(cropped);
    if (mounted) setState(() => _qrPath = saved);
  }

  Future<void> _remove() async {
    await PaymentProfileService.clear();
    if (mounted) setState(() => _qrPath = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        leading: Icon(Icons.qr_code_2),
        title: Text('Payment QR'),
        subtitle: Text('Loading…'),
      );
    }
    return ListTile(
      leading: const Icon(Icons.qr_code_2),
      title: const Text('Your payment QR'),
      subtitle: Text(_qrPath == null
          ? 'Add your DuitNow / bank QR to print it on receipts'
          : 'Tap to replace · printed on every receipt'),
      trailing: _qrPath == null
          ? FilledButton.tonal(onPressed: _pick, child: const Text('Add'))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(File(_qrPath!),
                      width: 44, height: 44, fit: BoxFit.cover),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove',
                  onPressed: _remove,
                ),
              ],
            ),
      onTap: _qrPath == null ? _pick : _pick,
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile();

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final updated = currency.updatedAt;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.attach_money),
          title: const Text('Display currency'),
          subtitle: Text(currency.displayCurrency.name),
          trailing: DropdownButton<String>(
            value: currency.displayCode,
            underline: const SizedBox(),
            items: [
              for (final c in supportedCurrencies)
                DropdownMenuItem(value: c.code, child: Text('${c.code}  ${c.symbol}')),
            ],
            onChanged: (code) {
              if (code != null) currency.setDisplayCurrency(code);
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Update exchange rates'),
          subtitle: Text(
            currency.refreshing
                ? 'Updating…'
                : updated != null
                    ? 'Last updated ${_fmt(updated)}'
                    : 'Using saved/offline rates — tap to update',
          ),
          trailing: currency.refreshing
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
          onTap: currency.refreshing
              ? null
              : () async {
                  final ok = await currency.refreshRates();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? 'Exchange rates updated.'
                          : 'Couldn\'t reach the rate service — keeping saved rates.'),
                    ));
                  }
                },
        ),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _BackupTiles extends StatelessWidget {
  const _BackupTiles();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Export backup'),
          subtitle: const Text('Save a signed .splitaa file you can restore later'),
          onTap: () async {
            try {
              final path = await BackupService.export();
              await SharePlus.instance.share(
                ShareParams(files: [XFile(path)], text: 'Splitaa backup'),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Import backup'),
          subtitle: const Text('Restore from a .splitaa file (replaces current data)'),
          onTap: () => _confirmAndImport(context),
        ),
      ],
    );
  }

  Future<void> _confirmAndImport(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
            'This replaces all current ledger data with the contents of the backup file.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
        ],
      ),
    );
    if (proceed != true) return;

    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null) return;

    final result = await BackupService.import(path);
    if (result.status == ImportStatus.success && context.mounted) {
      await context.read<ChecklistProvider>().fetchEntries();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class _NotificationsTile extends StatefulWidget {
  const _NotificationsTile();

  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    NotificationService.hasPermission().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _request() async {
    await NotificationService.requestPermission();
    final enabled = await NotificationService.hasPermission();
    if (mounted) setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: const Text('Debt reminders'),
      subtitle: Text(_enabled == null
          ? 'Checking…'
          : _enabled!
              ? 'Enabled — set reminders from any ledger entry'
              : 'Tap to allow notifications for due-date reminders'),
      trailing: _enabled == false
          ? FilledButton.tonal(onPressed: _request, child: const Text('Enable'))
          : _enabled == true
              ? const Icon(Icons.check_circle_outline, color: Colors.green)
              : null,
    );
  }
}
