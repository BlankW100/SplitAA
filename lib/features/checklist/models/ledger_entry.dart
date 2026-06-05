class LedgerEntry {
  final String id;
  final String title;
  final double totalAmount;
  final String? debtorIdentifier;
  final bool isSettled;
  final DateTime createdAt;
  final DateTime? dueDate;

  LedgerEntry({
    required this.id,
    required this.title,
    required this.totalAmount,
    this.debtorIdentifier,
    required this.isSettled,
    required this.createdAt,
    this.dueDate,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'total_amount': totalAmount,
        'debtor_identifier': debtorIdentifier,
        'is_settled': isSettled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
      };

  static LedgerEntry fromJson(Map<String, Object?> json) => LedgerEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        totalAmount: json['total_amount'] as double,
        debtorIdentifier: json['debtor_identifier'] as String?,
        isSettled: json['is_settled'] == 1,
        createdAt: DateTime.parse(json['created_at'] as String),
        dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      );
}
