import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checklist_provider.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

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
              return ListTile(
                title: Text(entry.title),
                subtitle: Text('Amount: \$${entry.totalAmount.toStringAsFixed(2)}'),
                trailing: Checkbox(
                  value: entry.isSettled,
                  onChanged: (_) => provider.toggleSettled(entry.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
