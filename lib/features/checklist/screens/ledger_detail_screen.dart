import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checklist_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../receipt/models/receipt_result.dart';

class LedgerDetailScreen extends StatelessWidget {
  final String entryId;
  const LedgerDetailScreen({super.key, required this.entryId});

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _pickReminder(BuildContext context, String id, String name, double amount) async {
    // Pick date.
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Reminder date',
    );
    if (date == null || !context.mounted) return;

    // Pick time.
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Reminder time',
    );
    if (time == null || !context.mounted) return;

    final scheduledDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final hasPermission = await NotificationService.hasPermission();
    if (!hasPermission && context.mounted) {
      await NotificationService.requestPermission();
    }

    if (!context.mounted) return;
    await context.read<ChecklistProvider>().setDueDate(id, scheduledDate);
    await NotificationService.scheduleReminder(
      entryId: id,
      personName: name,
      amount: amount,
      scheduledDate: scheduledDate,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${_fmtDate(scheduledDate)}')),
      );
    }
  }

  Future<void> _clearReminder(BuildContext context, String id) async {
    await context.read<ChecklistProvider>().setDueDate(id, null);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Details')),
      body: Consumer<ChecklistProvider>(
        builder: (context, provider, _) {
          final matches = provider.entries.where((e) => e.id == entryId);
          if (matches.isEmpty) {
            return const Center(child: Text('This entry no longer exists.'));
          }
          final entry = matches.first;
          final receipt = ReceiptResult.fromStorageJson(entry.payload);
          final name = entry.debtorIdentifier ?? entry.title;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(entry.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Created ${_fmtDate(entry.createdAt)}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),

                if (receipt != null)
                  _buildBreakdown(context, receipt)
                else
                  Card(
                    child: ListTile(
                      title: const Text('Total'),
                      trailing: Text('RM ${entry.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                const SizedBox(height: 16),

                // Reminder card
                if (!entry.isSettled) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.alarm_outlined, size: 18),
                              const SizedBox(width: 6),
                              Text('Reminder', style: theme.textTheme.labelLarge),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (entry.dueDate != null) ...[
                            Text(
                              'Scheduled: ${_fmtDate(entry.dueDate!)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickReminder(context, entry.id, name, entry.totalAmount),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Change'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _clearReminder(context, entry.id),
                                    icon: const Icon(Icons.alarm_off_outlined, size: 16),
                                    label: const Text('Clear'),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _pickReminder(context, entry.id, name, entry.totalAmount),
                                icon: const Icon(Icons.add_alarm_outlined, size: 18),
                                label: const Text('Set reminder'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Settle toggle
                FilledButton.tonalIcon(
                  onPressed: () => provider.toggleSettled(entry.id),
                  icon: Icon(entry.isSettled ? Icons.undo : Icons.check_circle_outline),
                  label: Text(entry.isSettled ? 'Mark as unpaid' : 'Mark as paid'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreakdown(BuildContext context, ReceiptResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items', style: Theme.of(context).textTheme.labelLarge),
            const Divider(),
            ...r.items.map((item) => _row(
                  item.quantity > 1 ? '${item.quantity}× ${item.name}' : item.name,
                  'RM ${item.price.toStringAsFixed(2)}',
                )),
            const Divider(),
            _row('Subtotal', 'RM ${r.subtotal.toStringAsFixed(2)}', muted: true),
            ...r.fees.map((fee) {
              final amount = fee.compute(r.subtotal);
              return _row(
                fee.label,
                '${amount < 0 ? '-' : '+'}RM ${amount.abs().toStringAsFixed(2)}',
                muted: true,
                green: fee.isDiscount,
              );
            }),
            const Divider(),
            _row('Total', 'RM ${r.total.toStringAsFixed(2)}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool muted = false, bool bold = false, bool green = false}) {
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
