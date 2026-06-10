class ReceiptItem {
  final String id;
  String name;

  /// The line total as printed on the receipt (covers all [quantity] units).
  double price;

  /// How many of this item — defaults to 1. Informational: [price] is already
  /// the total for the whole line, so the subtotal stays a plain sum of prices.
  int quantity;

  bool isSelected;
  String? assignedToQr;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.isSelected = false,
    this.assignedToQr,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory ReceiptItem.fromJson(Map<String, dynamic> json, String id) =>
      ReceiptItem(
        id: id,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}
