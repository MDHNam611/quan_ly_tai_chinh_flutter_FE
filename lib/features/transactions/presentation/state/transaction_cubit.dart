import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/models/transaction_model.dart';
import 'package:uuid/uuid.dart'; 
import 'package:do_an_quan_ly_tai_chinh/core/helpers/database_helper.dart';

// Định nghĩa các trạng thái
abstract class TransactionState {}
class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  TransactionLoaded(this.transactions);
}
class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}

// Lớp Cubit điều khiển logic
class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository repository;

  TransactionCubit({required this.repository}) : super(TransactionInitial());

  Future<void> loadTransactions() async {
    try {
      // Tạm thời tắt emit(TransactionLoading()) ở đây để tránh giao diện bị chớp nháy khi thêm giao dịch
      final data = await repository.getTransactions();
      
      // Tạo một vùng nhớ mới cho List để ép UI rebuild
      emit(TransactionLoaded(List.from(data))); 
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      emit(TransactionLoading());
      await repository.addTransaction(transaction);
      // Thêm xong thì tự động load lại danh sách
      await loadTransactions(); 
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      emit(TransactionLoading());
      await repository.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> duplicateTransaction(TransactionModel tx) async {
    try {
      emit(TransactionLoading());
      // Giữ nguyên ngày theo yêu cầu của bạn, chỉ đổi offlineId và bỏ id (để tự tăng)
      final newTx = TransactionModel(
        accountId: tx.accountId,
        category: tx.category,
        type: tx.type,
        amount: tx.amount,
        note: tx.note,
        date: tx.date, 
        offlineId: const Uuid().v4(), // Phải import 'package:uuid/uuid.dart';
        isSynced: 0,
      );
      await repository.addTransaction(newTx);
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    try {
      emit(TransactionLoading());
      await repository.updateTransaction(tx);
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
  // Hàm Xóa Giao dịch an toàn (Có hoàn tiền lại ví)
  Future<void> deleteTransactionSecure(TransactionModel tx) async {
    try {
      // Vì bạn đang dùng repository, nhưng để xử lý Transaction DB an toàn và nhanh gọn nhất, 
      // ta gọi thẳng DatabaseHelper ở đây (Nhớ import DatabaseHelper nếu chưa có)
      final db = await DatabaseHelper.instance.database;
      
      await db.transaction((txn) async {
        // 1. Hoàn tiền lại ví
        if (tx.type == 'expense') {
          await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, tx.accountId]);
        } else if (tx.type == 'income') {
          await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, tx.accountId]);
        }
        
        // 2. Xóa lịch sử (Dùng offlineId làm khóa chính an toàn)
        await txn.delete('transactions', where: 'offlineId = ?', whereArgs: [tx.offlineId]);
      });
      
      // Load lại danh sách sau khi xóa
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // Hàm Đổi ngày giao dịch
  Future<void> updateTransactionDate(String offlineId, DateTime newDate) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'transactions', 
        {'date': newDate.toIso8601String()}, 
        where: 'offlineId = ?', 
        whereArgs: [offlineId]
      );
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // Yêu cầu 5: Thay đổi Tài khoản (Xử lý hoàn tiền ví cũ -> Trừ tiền ví mới)
  Future<void> updateTransactionAccount(TransactionModel tx, String newAccountId) async {
    if (tx.accountId == newAccountId) return; // Không làm gì nếu chọn lại ví cũ

    try {
      final db = await DatabaseHelper.instance.database;
      
      await db.transaction((txn) async {
        // 1. TRẢ LẠI TIỀN CHO VÍ CŨ
        if (tx.type == 'expense') {
          await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, tx.accountId]);
        } else if (tx.type == 'income') {
          await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, tx.accountId]);
        }
        
        // 2. TRỪ TIỀN Ở VÍ MỚI
        if (tx.type == 'expense') {
          await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, newAccountId]);
        } else if (tx.type == 'income') {
          await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, newAccountId]);
        }
        
        // 3. CẬP NHẬT LỊCH SỬ GIAO DỊCH
        await txn.update('transactions', {'accountId': newAccountId}, where: 'offlineId = ?', whereArgs: [tx.offlineId]);
      });
      
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // Yêu cầu 6: Thay đổi Danh mục
  Future<void> updateTransactionCategory(String offlineId, String newCategory) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'transactions', 
        {'category': newCategory}, 
        where: 'offlineId = ?', 
        whereArgs: [offlineId]
      );
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // HÀM XÓA HÀNG LOẠT GIAO DỊCH AN TOÀN (Bọc trong 1 Transaction duy nhất)
  Future<void> deleteMultipleTransactionsSecure(List<TransactionModel> txs) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Bọc toàn bộ quá trình hoàn tiền + xóa vào 1 transaction db
      await db.transaction((txn) async {
        for (var tx in txs) {
          // 1. Hoàn tiền lại ví cho TỪNG giao dịch
          if (tx.type == 'expense') {
            await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, tx.accountId]);
          } else if (tx.type == 'income') {
            await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, tx.accountId]);
          }
          
          // 2. Xóa khỏi lịch sử
          await txn.delete('transactions', where: 'offlineId = ?', whereArgs: [tx.offlineId]);
        }
      });
      
      // Chỉ load lại 1 lần sau khi đã quét dọn xong toàn bộ
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
  // --- CÁC HÀM XỬ LÝ HÀNG LOẠT (BULK ACTIONS) ---

  // 1. Đổi ngày hàng loạt
  Future<void> updateMultipleTransactionsDate(List<TransactionModel> txs, DateTime newDate) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        for (var tx in txs) {
          await txn.update('transactions', {'date': newDate.toIso8601String()}, where: 'offlineId = ?', whereArgs: [tx.offlineId]);
        }
      });
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // 2. Đổi tài khoản hàng loạt (Xử lý hoàn tiền ví cũ -> Tính tiền ví mới)
  Future<void> updateMultipleTransactionsAccount(List<TransactionModel> txs, String newAccountId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        for (var tx in txs) {
          if (tx.accountId == newAccountId) continue; // Bỏ qua nếu ví cũ và mới giống nhau

          // A. TRẢ TIỀN LẠI VÍ CŨ
          if (tx.type == 'expense') {
            await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, tx.accountId]);
          } else if (tx.type == 'income') {
            await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, tx.accountId]);
          }
          
          // B. TRỪ/CỘNG TIỀN VÍ MỚI
          if (tx.type == 'expense') {
            await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [tx.amount, newAccountId]);
          } else if (tx.type == 'income') {
            await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [tx.amount, newAccountId]);
          }
          
          // C. CẬP NHẬT LỊCH SỬ
          await txn.update('transactions', {'accountId': newAccountId}, where: 'offlineId = ?', whereArgs: [tx.offlineId]);
        }
      });
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // 3. Đổi danh mục hàng loạt
  Future<void> updateMultipleTransactionsCategory(List<TransactionModel> txs, String newCategory) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        for (var tx in txs) {
          await txn.update('transactions', {'category': newCategory}, where: 'offlineId = ?', whereArgs: [tx.offlineId]);
        }
      });
      await loadTransactions();
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}