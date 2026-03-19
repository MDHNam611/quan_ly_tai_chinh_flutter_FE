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

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL, -- 'income' hoặc 'expense'
        icon TEXT NOT NULL,
        color TEXT NOT NULL -- Mã màu Hex (VD: #FF0000) để vẽ biểu đồ
      )
    ''');

    await db.insert('categories', {'id': 'cat_inc_1', 'name': 'Tiền lương', 'type': 'income', 'icon': 'payments', 'color': '#00BFA5'});
    await db.insert('categories', {'id': 'cat_inc_2', 'name': 'Khác', 'type': 'income', 'icon': 'more_horiz', 'color': '#9E9E9E'});
    
    // Chi phí
    await db.insert('categories', {'id': 'cat_exp_1', 'name': 'Đồ ăn', 'type': 'expense', 'icon': 'restaurant', 'color': '#3F51B5'});
    await db.insert('categories', {'id': 'cat_exp_2', 'name': 'Di chuyển', 'type': 'expense', 'icon': 'directions_car', 'color': '#FFB300'});
    await db.insert('categories', {'id': 'cat_exp_3', 'name': 'Khác', 'type': 'expense', 'icon': 'more_horiz', 'color': '#9E9E9E'});

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