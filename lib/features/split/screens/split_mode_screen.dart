import 'dart:io';
import 'package:flutter/material.dart';
import '../../scanner/models/receipt_item.dart';
import '../../calculator/screens/fee_calculator_screen.dart';
import 'person_split_screen.dart';

/// Shown right after a scan: the user picks how to split before doing anything
/// else. "By item" opens the per-person picker; "Evenly" totals everything up
/// and goes straight to fees.
class SplitModeScreen extends StatelessWidget {
  final List<ReceiptItem> items;
  final String? imagePath;

  const SplitModeScreen({super.key, required this.items, this.imagePath});

  double get _total => items.fold(0.0, (s, i) => s + i.price);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('How to split?')),
      body: SafeArea(
        child: Column(
          children: [
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(imagePath!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${items.length} item(s) detected  ·  RM ${_total.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ModeCard(
                    icon: Icons.person_search_outlined,
                    title: 'Split by item',
                    subtitle:
                        'Name each person and pick what they had. Everyone gets their own bill & QR.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PersonSplitScreen(items: items, imagePath: imagePath),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.groups_outlined,
                    title: 'Split evenly',
                    subtitle:
                        'Total everything up, add tax / discount, and produce one shared bill.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeeCalculatorScreen(items: items),
                      ),
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

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
