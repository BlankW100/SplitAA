import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checklist_provider.dart';
import 'ledger_detail_screen.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  String _fmtDue(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger')),
      body: Consumer<ChecklistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.entries.isEmpty) return const Center(child: Text('No entries yet.'));
          return ListView.builder(
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final entry = provider.entries[index];
              final now = DateTime.now();
              final isOverdue = !entry.isSettled &&
                  entry.dueDate != null &&
                  entry.dueDate!.isBefore(now);

              return ListTile(
                tileColor: isOverdue
                    ? Colors.red.shade50
                    : null,
                title: Text(
                  entry.title,
                  style: TextStyle(
                    color: isOverdue ? Colors.red.shade700 : null,
                    fontWeight: isOverdue ? FontWeight.bold : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM ${entry.totalAmount.toStringAsFixed(2)}'
                      '${entry.isSettled ? '  ·  Paid' : ''}',
                      style: TextStyle(
                        color: entry.isSettled ? Colors.green.shade700 : null,
                      ),
                    ),
                    if (entry.dueDate != null && !entry.isSettled)
                      Row(
                        children: [
                          Icon(
                            isOverdue ? Icons.alarm_on : Icons.alarm_outlined,
                            size: 12,
                            color: isOverdue ? Colors.red.shade600 : Colors.grey,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isOverdue
                                ? 'Overdue · ${_fmtDue(entry.dueDate!)}'
                                : 'Reminder · ${_fmtDue(entry.dueDate!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue ? Colors.red.shade600 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: Checkbox(
                  value: entry.isSettled,
                  onChanged: (_) => provider.toggleSettled(entry.id),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LedgerDetailScreen(entryId: entry.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
