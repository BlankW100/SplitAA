import 'package:flutter/foundation.dart';
import '../models/ledger_entry.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/services/notification_service.dart';

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
    if (index == -1) return;
    final entry = _entries[index];
    final settled = !entry.isSettled;
    final updated = LedgerEntry(
      id: entry.id,
      title: entry.title,
      totalAmount: entry.totalAmount,
      debtorIdentifier: entry.debtorIdentifier,
      isSettled: settled,
      createdAt: entry.createdAt,
      dueDate: entry.dueDate,
      payload: entry.payload,
    );
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ledger',
      {'is_settled': settled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    // Cancel reminder when marked as paid.
    if (settled) await NotificationService.cancelReminder(id);
    _entries[index] = updated;
    notifyListeners();
  }

  Future<void> setDueDate(String id, DateTime? dueDate) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final entry = _entries[index];
    final updated = LedgerEntry(
      id: entry.id,
      title: entry.title,
      totalAmount: entry.totalAmount,
      debtorIdentifier: entry.debtorIdentifier,
      isSettled: entry.isSettled,
      createdAt: entry.createdAt,
      dueDate: dueDate,
      payload: entry.payload,
    );
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ledger',
      {'due_date': dueDate?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    // Cancel old reminder regardless; caller schedules a new one if needed.
    await NotificationService.cancelReminder(id);
    _entries[index] = updated;
    notifyListeners();
  }
}
