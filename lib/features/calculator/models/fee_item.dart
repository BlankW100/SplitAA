class FeeItem {
  final String id;
  String label;
  bool isEnabled;
  bool isPercentage;
  double value;
  final bool isDiscount;

  FeeItem({
    required this.id,
    required this.label,
    this.isEnabled = false,
    this.isPercentage = true,
    this.value = 0.0,
    this.isDiscount = false,
  });

  /// Returns the signed amount this fee contributes to the total.
  /// Discounts return a negative value; charges return positive.
  double compute(double subtotal) {
    if (!isEnabled || value <= 0) return 0.0;
    final amount = isPercentage ? subtotal * (value / 100) : value;
    return isDiscount ? -amount : amount;
  }

  /// One person's share when splitting a bill among [partySize] people.
  /// A percentage fee is naturally per-person (applied to their own subtotal);
  /// a fixed RM amount is divided equally across the whole party.
  double computeShare(double subtotal, int partySize) {
    if (!isEnabled || value <= 0) return 0.0;
    final amount = isPercentage
        ? subtotal * (value / 100)
        : value / (partySize < 1 ? 1 : partySize);
    return isDiscount ? -amount : amount;
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'isPercentage': isPercentage,
        'value': value,
        'isDiscount': isDiscount,
      };

  factory FeeItem.fromJson(Map<String, dynamic> json, String id) => FeeItem(
        id: id,
        label: json['label'] as String,
        isEnabled: true,
        isPercentage: json['isPercentage'] as bool? ?? true,
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        isDiscount: json['isDiscount'] as bool? ?? false,
      );
}
