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
  final Map<String, double> chartData; // ĐÃ NÂNG CẤP: Dùng chuỗi ngày tháng làm key (VD: "21/03")
  final DateTime? startDate;
  final DateTime? endDate;

  DashboardLoaded({
    required this.totalIncome, 
    required this.totalExpense, 
    required this.netBalance,
    required this.chartData,
    this.startDate,
    this.endDate,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class DashboardCubit extends Cubit<DashboardState> {
  final DatabaseHelper dbHelper;

  DashboardCubit({required this.dbHelper}) : super(DashboardInitial());

  // Vẫn giữ hàm cũ để tương thích ngược nếu có chỗ nào lỡ gọi
  Future<void> loadDashboardData(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    await loadDashboardDataRange(start, end);
  }

  // HÀM MỚI: Tải dữ liệu theo bất kỳ khoảng thời gian nào
  Future<void> loadDashboardDataRange(DateTime? startDate, DateTime? endDate) async {
    try {
      emit(DashboardLoading());
      final db = await dbHelper.database;
      
      List<Map<String, dynamic>> maps;

      // Nếu có chọn ngày (Tháng, Tuần, Hôm nay...)
      if (startDate != null && endDate != null) {
        maps = await db.query(
          'transactions',
          where: 'date >= ? AND date <= ?',
          whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        );
      } else {
        // Nếu chọn "Tất cả thời gian"
        maps = await db.query('transactions');
      }

      final transactions = maps.map((e) => TransactionModel.fromMap(e)).toList();

      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> chartData = {};

      // Tạo map mặc định cho biểu đồ nếu khoảng thời gian dưới 31 ngày (để biểu đồ không bị đứt quãng)
      if (startDate != null && endDate != null && endDate.difference(startDate).inDays <= 31) {
        DateTime current = startDate;
        while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
          String dateKey = DateFormat('dd/MM').format(current);
          chartData[dateKey] = 0.0;
          current = current.add(const Duration(days: 1));
        }
      }

      for (var tx in transactions) {
        if (tx.type == 'income') {
          totalIncome += tx.amount;
        } else if (tx.type == 'expense') {
          totalExpense += tx.amount;
          
          final txDate = DateTime.parse(tx.date);
          // Định dạng key tùy theo "Tất cả thời gian" hay "Ngày cụ thể"
          String dateKey = (startDate == null) 
              ? DateFormat('MM/yyyy').format(txDate) 
              : DateFormat('dd/MM').format(txDate);
          
          chartData[dateKey] = (chartData[dateKey] ?? 0) + tx.amount;
        }
      }

      emit(DashboardLoaded(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        chartData: chartData,
        startDate: startDate,
        endDate: endDate,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}