import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/currency/currency.dart';
import '../../../core/currency/currency_provider.dart';
import '../../checklist/providers/checklist_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          _SectionHeader('Currency'),
          _CurrencyTile(),
          Divider(),
          _SectionHeader('Backup'),
          _BackupTiles(),
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
