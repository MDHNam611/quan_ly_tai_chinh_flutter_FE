import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Đã đổi tên file thành v2 để ép SQLite tạo mới cấu trúc bảng hoàn toàn
    _database = await _initDB('finance_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tạo bảng Giao dịch (Đã bổ sung toAccountId cho tính năng chuyển khoản)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mongoId TEXT,
        accountId TEXT NOT NULL,
        toAccountId TEXT, 
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        offlineId TEXT NOT NULL
      )
    ''');
    
    // 2. Tạo bảng Tài khoản (Đã bổ sung description và icon để hỗ trợ Form Chỉnh sửa)
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        description TEXT,
        icon TEXT
      )
    ''');

    // 3. Tạo sẵn ví "Tiền mặt" mặc định ngay khi mở app lần đầu
    await db.insert('accounts', {
      'id': 'cash_1', 
      'name': 'Tiền mặt', 
      'balance': 0,
      'description': 'Ví mặc định',
      'icon': 'wallet'
    });
  }
}