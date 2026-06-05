import 'package:drift/drift.dart';

class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get dateScanned => dateTime()();
  RealColumn get totalAmount => real()();
  TextColumn get merchantName => text().nullable()();
}

class SplitChecklist extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId => integer().references(Receipts, #id)();
  TextColumn get guestName => text()();
  RealColumn get amountOwed => real()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get reminderDate => dateTime().nullable()();
}