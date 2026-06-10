import 'package:uuid/uuid.dart';
import '../models/receipt_item.dart';

class OcrParser {
  static const _uuid = Uuid();

  static List<ReceiptItem> parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final items = <ReceiptItem>[];

    // Matches an optional currency symbol then a price at the end of a line.
    // Handles: 5.90  12.00  RM5.90  $ 12.00  MYR 3.50
    final pricePattern = RegExp(
      r'(?:RM|MYR|\$|£|€|SGD|USD)?\s*(\d{1,6}(?:\.\d{1,2})?)\s*$',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = pricePattern.firstMatch(line);
      if (match == null) continue;

      final price = double.tryParse(match.group(1)!);
      if (price == null || price <= 0 || price > 9999) continue;

      // Everything before the price match is the item name.
      final rawName = line.substring(0, match.start).trim();

      // Strip trailing dots/dashes used as price leaders: "Item .... 5.90"
      final name = rawName
          .replaceAll(RegExp(r'[\.\-\s]+$'), '')
          .replaceFirst(RegExp(r'^\d+\s*[xX×]\s*'), '') // remove "1x", "2 x"
          .trim();

      if (name.length < 2) continue;
      if (_isSummaryLine(name.toLowerCase())) continue;

      items.add(ReceiptItem(id: _uuid.v4(), name: name, price: price));
    }

    return items;
  }

  static bool _isSummaryLine(String lower) {
    const keywords = [
      'total', 'subtotal', 'sub total', 'sub-total',
      'tax', 'gst', 'sst', 'vat',
      'service charge', 'service fee',
      'discount', 'rounding', 'round',
      'change', 'cash', 'balance',
      'amount due', 'grand', 'nett', 'net',
      'payment', 'receipt', 'thank',
    ];
    return keywords.any((k) => lower.contains(k));
  }
}
