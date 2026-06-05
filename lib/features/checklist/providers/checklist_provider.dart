import 'package:flutter/foundation.dart';
import '../models/ledger_entry.dart';
import '../../../core/database/db_helper.dart';

class ChecklistProvider with ChangeNotifier {
  List<LedgerEntry> _entries = [];
  bool _isLoading = false;

  List<LedgerEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> fetchEntries() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final result = await db.query('ledger', orderBy: 'created_at DESC');

    _entries = result.map((json) => LedgerEntry.fromJson(json)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(LedgerEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('ledger', entry.toJson());
    _entries.insert(0, entry);
    notifyListeners();
  }

  Future<void> toggleSettled(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = _entries[index];
      final newEntry = LedgerEntry(
        id: entry.id,
        title: entry.title,
        totalAmount: entry.totalAmount,
        debtorIdentifier: entry.debtorIdentifier,
        isSettled: !entry.isSettled,
        createdAt: entry.createdAt,
        dueDate: entry.dueDate,
      );
      
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'ledger',
        {'is_settled': newEntry.isSettled ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );

      _entries[index] = newEntry;
      notifyListeners();
    }
  }
}
