class ReceiptItem {
  final String id;
  String name;
  double price;
  bool isSelected;
  String? assignedToQr;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    this.isSelected = false,
    this.assignedToQr,
  });
}
