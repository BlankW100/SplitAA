import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('splitaa.db');
    return _database!;
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }
  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE ledger (id TEXT PRIMARY KEY, title TEXT NOT NULL, total_amount REAL NOT NULL, debtor_identifier TEXT, is_settled INTEGER NOT NULL, created_at TEXT NOT NULL, due_date TEXT)''');
  }
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
