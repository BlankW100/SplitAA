import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../checklist/models/ledger_entry.dart';
import '../../checklist/providers/checklist_provider.dart';
import '../../../core/currency/currency_provider.dart';

/// A friendly, non-technical view of spending over time. Reads the same saved
/// records as the Ledger and presents them as a monthly overview with a simple
/// bar chart and a grouped transaction list.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spending')),
      body: Consumer2<ChecklistProvider, CurrencyProvider>(
        builder: (context, ledger, currency, _) {
          if (ledger.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = ledger.entries;
          if (entries.isEmpty) {
            return const _Empty();
          }

          final now = DateTime.now();
          final thisMonthTotal = entries
              .where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month)
              .fold(0.0, (s, e) => s + e.totalAmount);

          final monthly = _lastSixMonths(entries, now);
          final maxVal = monthly.map((m) => m.total).fold(0.0, (a, b) => a > b ? a : b);
          final grouped = _groupByMonth(entries);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Big "this month" headline
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Spent this month',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(thisMonthTotal),
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Simple 6-month bar chart
              Text('Last 6 months', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final m in monthly)
                      Expanded(
                        child: _Bar(
                          heightFactor: maxVal > 0 ? m.total / maxVal : 0,
                          label: _months[m.month - 1],
                          value: m.total > 0 ? currency.format(m.total) : '',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Grouped transactions
              Text('All transactions', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final group in grouped) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(group.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(currency.format(group.total),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
                for (final e in group.entries)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.receipt_long_outlined),
                      ),
                      title: Text(e.title),
                      subtitle: Text(_friendlyDate(e.createdAt)),
                      trailing: Text(currency.format(e.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  static List<_MonthBucket> _lastSixMonths(List<LedgerEntry> entries, DateTime now) {
    final buckets = <_MonthBucket>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      final total = entries
          .where((e) => e.createdAt.year == d.year && e.createdAt.month == d.month)
          .fold(0.0, (s, e) => s + e.totalAmount);
      buckets.add(_MonthBucket(d.month, d.year, total, const []));
    }
    return buckets;
  }

  static List<_MonthBucket> _groupByMonth(List<LedgerEntry> entries) {
    final sorted = [...entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final map = <String, List<LedgerEntry>>{};
    for (final e in sorted) {
      final key = '${e.createdAt.year}-${e.createdAt.month}';
      map.putIfAbsent(key, () => []).add(e);
    }
    return map.entries.map((kv) {
      final first = kv.value.first.createdAt;
      final total = kv.value.fold(0.0, (s, e) => s + e.totalAmount);
      return _MonthBucket(first.month, first.year, total, kv.value);
    }).toList();
  }

  static String _friendlyDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';
}

class _MonthBucket {
  final int month;
  final int year;
  final double total;
  final List<LedgerEntry> entries;
  const _MonthBucket(this.month, this.year, this.total, this.entries);

  String get label => '${HistoryScreen._months[month - 1]} $year';
}

class _Bar extends StatelessWidget {
  final double heightFactor; // 0..1
  final String label;
  final String value;
  const _Bar({required this.heightFactor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 9), maxLines: 1, overflow: TextOverflow.clip),
        const SizedBox(height: 2),
        Expanded(
          child: FractionallySizedBox(
            heightFactor: heightFactor.clamp(0.02, 1.0),
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: heightFactor > 0 ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Text('No spending yet.\nScan a receipt and save it to see it here.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
