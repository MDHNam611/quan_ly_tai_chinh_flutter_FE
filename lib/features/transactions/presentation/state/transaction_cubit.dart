import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/models/transaction_model.dart';
import 'package:uuid/uuid.dart'; 

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
      emit(TransactionLoading());
      final data = await repository.getTransactions();
      emit(TransactionLoaded(data));
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
}