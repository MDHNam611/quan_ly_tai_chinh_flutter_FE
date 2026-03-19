import '../datasources/local_datasource.dart';
import '../models/transaction_model.dart';
// Đã sửa import trỏ về đúng thư mục domain
import 'package:do_an_quan_ly_tai_chinh/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl(this.localDataSource);

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await localDataSource.addTransaction(transaction);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return await localDataSource.getTransactions();
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await localDataSource.deleteTransaction(id);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await localDataSource.updateTransaction(transaction);
  }

  @override
  Future<void> updateSyncStatus(String offlineId, String mongoId) async {
    await localDataSource.updateSyncStatus(offlineId, mongoId);
  }
}