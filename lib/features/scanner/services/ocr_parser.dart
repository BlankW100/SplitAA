import 'dart:ui' show Rect;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_item.dart';

/// Turns raw OCR output into a list of [ReceiptItem]s.
///
/// Receipts are laid out in two columns: an item name on the left and its
/// price on the right. ML Kit frequently returns those two columns as
/// *separate* text blocks, so a simple "price at end of line" regex misses
/// most rows. [parseRecognized] uses the bounding-box geometry to pair a
/// price with the name that sits on the same horizontal row, which recovers
/// far more items than text-only parsing.
class OcrParser {
  static const _uuid = Uuid();

  // A monetary amount: 5.90, 12.00, 1,234.50, 1.234,50 (we keep the last 2
  // decimals). Requiring 2 decimals strongly filters out quantities, dates,
  // phone numbers, etc.
  static final _priceAtEnd = RegExp(
    r'(?:RM|MYR|\$|£|€|SGD|USD)?\s*'
    r'(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d{1,5}[.,]\d{2})'
    r'\s*[A-Za-z*#]{0,2}\s*$',
    caseSensitive: false,
  );

  /// Preferred entry point — uses bounding boxes to pair names with prices.
  static List<ReceiptItem> parseRecognized(RecognizedText recognized) {
    final lines = <_OcrLine>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        lines.add(_OcrLine(text: text, box: line.boundingBox));
      }
    }
    if (lines.isEmpty) return parse(recognized.text);

    // Pass 1: classify each line — does it end with a price, and what's the
    // name part before that price (if any)?
    for (final l in lines) {
      final m = _priceAtEnd.firstMatch(l.text);
      if (m == null) continue;
      final price = _toDouble(m.group(1)!);
      if (price == null || price <= 0 || price > 99999) continue;
      l.price = price;
      l.namePart = _cleanName(l.text.substring(0, m.start));
    }

    // Everything from the first "subtotal/total/amount due/balance" line down
    // is the receipt footer (tax, service, discount, change…) — never items.
    final footerTop = _footerTop(lines);

    final items = <ReceiptItem>[];
    final consumed = <_OcrLine>{};

    // Pass 2: build items.
    for (final l in lines) {
      if (l.price == null) continue;
      if (footerTop != null && l.box.center.dy >= footerTop) continue;

      String? rawName;
      if (l.namePart != null && l.namePart!.isNotEmpty) {
        // Self-contained row: "Nasi Lemak   5.90"
        rawName = l.namePart;
      } else {
        // Price-only line: find the nearest name on the same row, to its left.
        final nameLine = _matchNameForPrice(lines, l, consumed);
        if (nameLine == null) continue;
        consumed.add(nameLine);
        rawName = _cleanName(nameLine.text);
      }

      final (name, qty) = _nameAndQuantity(rawName!);
      if (name.length < 2 || _isSummaryLine(name.toLowerCase())) continue;
      items.add(
        ReceiptItem(id: _uuid.v4(), name: name, price: l.price!, quantity: qty),
      );
    }

    // If geometry pairing found nothing useful, fall back to text parsing.
    if (items.isEmpty) return parse(recognized.text);
    return items;
  }

  /// Finds the best name line for a price-only line by vertical row overlap.
  static _OcrLine? _matchNameForPrice(
    List<_OcrLine> lines,
    _OcrLine priceLine,
    Set<_OcrLine> consumed,
  ) {
    final pCenter = priceLine.box.center.dy;
    final tolerance = priceLine.box.height * 0.8;
    _OcrLine? best;
    double bestDist = double.infinity;
    for (final c in lines) {
      if (identical(c, priceLine) || consumed.contains(c)) continue;
      if (c.price != null) continue; // skip other price lines
      if (c.text.trim().length < 2) continue;
      if (c.box.left >= priceLine.box.left) continue; // name must be on the left
      final dist = (c.box.center.dy - pCenter).abs();
      if (dist <= tolerance && dist < bestDist) {
        bestDist = dist;
        best = c;
      }
    }
    return best;
  }

  /// Plain text fallback (no geometry).
  static List<ReceiptItem> parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final items = <ReceiptItem>[];
    var seenTotal = false;
    for (final line in lines) {
      final lower = line.toLowerCase();
      // Once we reach the totals block, stop collecting items.
      if (lower.contains('subtotal') ||
          lower.contains('amount due') ||
          RegExp(r'\btotal\b').hasMatch(lower)) {
        seenTotal = true;
      }
      if (seenTotal) continue;

      final match = _priceAtEnd.firstMatch(line);
      if (match == null) continue;
      final price = _toDouble(match.group(1)!);
      if (price == null || price <= 0 || price > 99999) continue;
      final (name, qty) = _nameAndQuantity(_cleanName(line.substring(0, match.start)));
      if (name.length < 2 || _isSummaryLine(name.toLowerCase())) continue;
      items.add(ReceiptItem(id: _uuid.v4(), name: name, price: price, quantity: qty));
    }
    return items;
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'[\.\-_\s]+$'), '') // trailing leader dots/dashes
        .replaceFirst(RegExp(r'^[\.\-_\s]+'), '') // leading junk
        .trim();
  }

  /// Pulls a leading/trailing quantity out of a name: "2x Coke", "2 Coke",
  /// "Coke x2" → ("Coke", 2). Returns the cleaned name and the quantity.
  static (String, int) _nameAndQuantity(String raw) {
    var s = raw.trim();
    int qty = 1;

    // "2 x Item" / "2x Item" / "2 × Item"
    var m = RegExp(r'^(\d{1,3})\s*[xX×]\s*(.+)').firstMatch(s);
    if (m != null) {
      qty = int.tryParse(m.group(1)!) ?? 1;
      s = m.group(2)!.trim();
    } else {
      // "Item x2" / "Item ×2"
      m = RegExp(r'^(.+?)\s*[xX×]\s*(\d{1,3})$').firstMatch(s);
      if (m != null) {
        s = m.group(1)!.trim();
        qty = int.tryParse(m.group(2)!) ?? 1;
      } else {
        // Bare leading quantity column: "2 Nasi Lemak"
        m = RegExp(r'^(\d{1,2})\s+([A-Za-z].*)').firstMatch(s);
        if (m != null) {
          qty = int.tryParse(m.group(1)!) ?? 1;
          s = m.group(2)!.trim();
        }
      }
    }

    if (qty < 1 || qty > 99) qty = 1; // sanity guard against codes/years
    return (s, qty);
  }

  /// Vertical position of the receipt footer (first total-ish line), or null.
  static double? _footerTop(List<_OcrLine> lines) {
    double? top;
    for (final l in lines) {
      final t = l.text.toLowerCase();
      final isFooter = t.contains('subtotal') ||
          t.contains('amount due') ||
          t.contains('balance') ||
          RegExp(r'\btotal\b').hasMatch(t);
      if (!isFooter) continue;
      if (top == null || l.box.top < top) top = l.box.top;
    }
    return top;
  }

  /// Parses "1,234.50" and "1.234,50" into a double.
  static double? _toDouble(String s) {
    var t = s.trim();
    final lastDot = t.lastIndexOf('.');
    final lastComma = t.lastIndexOf(',');
    if (lastComma > lastDot) {
      // comma is the decimal separator (European): strip dots, comma -> dot
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // dot is the decimal separator: strip thousands commas
      t = t.replaceAll(',', '');
    }
    return double.tryParse(t);
  }

  static bool _isSummaryLine(String lower) {
    const keywords = [
      'total', 'subtotal', 'sub total', 'sub-total',
      'tax', 'gst', 'sst', 'vat',
      'service charge', 'service fee', 'svc',
      'discount', 'rounding', 'round', 'adj',
      'change', 'cash', 'card', 'visa', 'master', 'balance',
      'amount due', 'amount', 'grand', 'nett', 'net',
      'payment', 'paid', 'receipt', 'invoice', 'thank',
      'qty', 'quantity', 'table', 'cashier', 'server',
    ];
    return keywords.any((k) => lower.contains(k));
  }
}

class _OcrLine {
  final String text;
  final Rect box;
  double? price;
  String? namePart;

  _OcrLine({required this.text, required this.box});
}
