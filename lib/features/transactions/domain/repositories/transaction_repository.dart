import '../../data/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<void> addTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getTransactions();
  Future<void> deleteTransaction(int id);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> updateSyncStatus(String offlineId, String mongoId);
}