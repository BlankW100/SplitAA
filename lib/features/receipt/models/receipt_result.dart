import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../scanner/models/receipt_item.dart';
import '../../calculator/models/fee_item.dart';

class ReceiptResult {
  final List<ReceiptItem> items;
  final List<FeeItem> fees;
  final double subtotal;
  final double total;
  final DateTime timestamp;

  /// Whose bill this is, for per-person split receipts. Null for a shared bill.
  final String? payerName;

  const ReceiptResult({
    required this.items,
    required this.fees,
    required this.subtotal,
    required this.total,
    required this.timestamp,
    this.payerName,
  });

  Map<String, dynamic> toMap() => {
        'app': 'splitaa',
        'timestamp': timestamp.toIso8601String(),
        'payerName': payerName,
        'items': items.map((i) => i.toJson()).toList(),
        'fees': fees.map((f) => f.toJson()).toList(),
        'subtotal': subtotal,
        'total': total,
      };

  /// Compact JSON for the QR payload and for persisting alongside a ledger entry.
  String toQrPayload() => jsonEncode(toMap());

  /// JSON stored in the ledger's `payload` column.
  String toStorageJson() => jsonEncode(toMap());

  static ReceiptResult fromMap(Map<String, dynamic> map) {
    const uuid = Uuid();
    final items = (map['items'] as List)
        .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>, uuid.v4()))
        .toList();
    final fees = (map['fees'] as List)
        .map((e) => FeeItem.fromJson(e as Map<String, dynamic>, uuid.v4()))
        .toList();
    return ReceiptResult(
      items: items,
      fees: fees,
      subtotal: (map['subtotal'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      payerName: map['payerName'] as String?,
    );
  }

  static ReceiptResult? fromStorageJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return fromMap(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
