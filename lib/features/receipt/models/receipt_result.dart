import 'dart:convert';
import '../../scanner/models/receipt_item.dart';
import '../../calculator/models/fee_item.dart';

class ReceiptResult {
  final List<ReceiptItem> items;
  final List<FeeItem> fees;
  final double subtotal;
  final double total;
  final DateTime timestamp;

  const ReceiptResult({
    required this.items,
    required this.fees,
    required this.subtotal,
    required this.total,
    required this.timestamp,
  });

  String toQrPayload() => jsonEncode({
        'app': 'splitaa',
        'timestamp': timestamp.toIso8601String(),
        'items': items.map((i) => {'name': i.name, 'price': i.price}).toList(),
        'fees': fees.map((f) => f.toJson()).toList(),
        'subtotal': subtotal,
        'total': total,
      });
}
