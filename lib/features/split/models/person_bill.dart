import 'package:uuid/uuid.dart';
import '../../scanner/models/receipt_item.dart';

/// One person's share of a split receipt.
class PersonBill {
  final String id;
  String name;
  final List<ReceiptItem> items;

  PersonBill({required this.id, required this.name, List<ReceiptItem>? items})
      : items = items ?? [];

  double get subtotal => items.fold(0.0, (s, i) => s + i.price);
  int get unitCount => items.fold(0, (s, i) => s + i.quantity);
}

/// Pure helpers for moving one unit of an item between the shared pool and a
/// person. [ReceiptItem.price] is the line total for its whole [quantity], so a
/// single unit is `price / quantity` computed against the *current* remaining
/// values — that way the final unit absorbs any rounding remainder exactly.
class SplitOps {
  static const _uuid = Uuid();

  /// Moves one unit of [poolItem] (identified by id) from [pool] to [person].
  static void assignUnit(List<ReceiptItem> pool, PersonBill person, String poolItemId) {
    final idx = pool.indexWhere((i) => i.id == poolItemId);
    if (idx == -1) return;
    final src = pool[idx];
    if (src.quantity <= 0) return;

    final unitPrice = src.price / src.quantity;

    // Reduce the pool item by one unit; drop it when empty.
    if (src.quantity == 1) {
      pool.removeAt(idx);
    } else {
      src.quantity -= 1;
      src.price -= unitPrice;
    }

    // Add to the person, merging with an existing line for the same name.
    final existing = person.items.where((i) => i.name == src.name);
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
      existing.first.price += unitPrice;
    } else {
      person.items.add(ReceiptItem(
        id: _uuid.v4(),
        name: src.name,
        price: unitPrice,
        quantity: 1,
      ));
    }
  }

  /// Returns one unit of [personItem] back to the shared [pool].
  static void returnUnit(List<ReceiptItem> pool, PersonBill person, String personItemId) {
    final idx = person.items.indexWhere((i) => i.id == personItemId);
    if (idx == -1) return;
    final src = person.items[idx];
    if (src.quantity <= 0) return;

    final unitPrice = src.price / src.quantity;

    if (src.quantity == 1) {
      person.items.removeAt(idx);
    } else {
      src.quantity -= 1;
      src.price -= unitPrice;
    }

    final existing = pool.where((i) => i.name == src.name);
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
      existing.first.price += unitPrice;
    } else {
      pool.add(ReceiptItem(
        id: _uuid.v4(),
        name: src.name,
        price: unitPrice,
        quantity: 1,
      ));
    }
  }
}
