import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/helpers/database_helper.dart';
import '../../../transactions/data/models/transaction_model.dart';

abstract class DashboardState {}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final double totalIncome;
  final double totalExpense;
  final double netBalance; // Thu trừ Chi
  final Map<int, double> dailyExpenses; // Dữ liệu cho biểu đồ Cột (Ngày -> Tổng chi)
  final DateTime selectedMonth;

  DashboardLoaded({
    required this.totalIncome, 
    required this.totalExpense, 
    required this.netBalance,
    required this.dailyExpenses,
    required this.selectedMonth,
  });
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class DashboardCubit extends Cubit<DashboardState> {
  final DatabaseHelper dbHelper;

  DashboardCubit({required this.dbHelper}) : super(DashboardInitial());

  Future<void> loadDashboardData(DateTime month) async {
    try {
      emit(DashboardLoading());
      final db = await dbHelper.database;
      
      // Lọc giao dịch theo tháng và năm được chọn
      final startDate = DateTime(month.year, month.month, 1).toIso8601String();
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59).toIso8601String();

      final maps = await db.query(
        'transactions',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDate, endDate],
      );

      final transactions = maps.map((e) => TransactionModel.fromMap(e)).toList();

      double totalIncome = 0;
      double totalExpense = 0;
      Map<int, double> dailyExpenses = {};

      // Tạo map mặc định cho tất cả các ngày trong tháng (bằng 0) để biểu đồ không bị đứt quãng
      int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        dailyExpenses[i] = 0.0;
      }

      for (var tx in transactions) {
        if (tx.type == 'income') {
          totalIncome += tx.amount;
        } else if (tx.type == 'expense') {
          totalExpense += tx.amount;
          
          // Lấy ngày của giao dịch để cộng dồn vào biểu đồ cột
          final txDate = DateTime.parse(tx.date);
          dailyExpenses[txDate.day] = (dailyExpenses[txDate.day] ?? 0) + tx.amount;
        }
      }

      emit(DashboardLoaded(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        dailyExpenses: dailyExpenses,
        selectedMonth: month,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}