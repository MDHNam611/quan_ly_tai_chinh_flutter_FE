import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import '../../../../core/helpers/database_helper.dart';

class TransactionLocalDataSource {
  final DatabaseHelper dbHelper;

  TransactionLocalDataSource(this.dbHelper);

  Future<void> addTransaction(TransactionModel tx) async {
    final db = await dbHelper.database;
    
    // Sử dụng transaction để đảm bảo lưu lịch sử và cập nhật tiền diễn ra đồng thời
    await db.transaction((txn) async {
      // 1. Lưu lịch sử giao dịch
      await txn.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      // 2. Cập nhật số dư vào bảng accounts tương ứng
      if (tx.type == 'income') {
        // Nạp tiền: Cộng vào ví
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, tx.accountId]);
      } else if (tx.type == 'expense') {
        // Rút tiền/Chi tiêu: Trừ từ ví
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, tx.accountId]);
      } else if (tx.type == 'transfer') {
        // Chuyển khoản: Trừ ví nguồn, Cộng ví đích
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, tx.accountId]);
        if (tx.toAccountId != null) {
          await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, tx.toAccountId]);
        }
      }
    });
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await dbHelper.database;
    // Lấy danh sách giao dịch, sắp xếp mới nhất lên đầu để hiển thị như Hình 2
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }
  Future<void> deleteTransaction(int id) async {
    final db = await dbHelper.database;
    await db.delete('transactions', where: 'id =?', whereArgs: [id]);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final db = await dbHelper.database;
    await db.update('transactions', tx.toMap(), where: 'id =?', whereArgs: [tx.id]);
  }

  // Cập nhật trạng thái đồng bộ và mongoId sau khi có phản hồi từ Server
  Future<void> updateSyncStatus(String offlineId, String mongoId) async {
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      {'isSynced': 1, 'mongoId': mongoId},
      where: 'offlineId = ?',
      whereArgs: [offlineId],
    );
  }
}