import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../state/dashboard_cubit.dart';
import '../widgets/summary_cards_widget.dart';
import '../widgets/bar_chart_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Mặc định chọn tháng hiện tại
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load dữ liệu khi vừa mở trang
    context.read<DashboardCubit>().loadDashboardData(_selectedMonth);
  }

  // Hàm lùi/tiến tháng
  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
    context.read<DashboardCubit>().loadDashboardData(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.white,
      // Tạm thời đặt Header ở đây. (Sẽ phân tích việc chuyển lên main_layout ở phần phản biện bên dưới)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_circle_outlined, color: Colors.black87, size: 28),
          onPressed: () {
            // TODO: Mở chức năng đăng nhập/đồng bộ Google
          },
        ),
        title: Column(
          children: [
            const Text('Tất cả các tài khoản', style: TextStyle(color: Colors.grey, fontSize: 12)),
            // TODO: Số dư này cần lấy từ AccountCubit (Tổng tất cả các ví), tạm thời để text tĩnh
            const Text('Đang tải...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: const [
          // Nút chức năng góc phải ẩn đi ở trang Tổng quan theo yêu cầu 2.1 của bạn
          SizedBox(width: 48), 
        ],
      ),
      body: Column(
        children: [
          // BỘ CHỌN THÁNG/NĂM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.keyboard_double_arrow_left, color: Colors.grey), onPressed: () => _changeMonth(-1)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6C4FF).withOpacity(0.3), // Màu nền tím nhạt
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedMonth.month} THÁNG ${_selectedMonth.month} ${_selectedMonth.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                IconButton(icon: const Icon(Icons.keyboard_double_arrow_right, color: Colors.grey), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),

          // NỘI DUNG CHÍNH: BIỂU ĐỒ & THỐNG KÊ
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DashboardError) {
                  return Center(child: Text('Lỗi: ${state.message}'));
                } else if (state is DashboardLoaded) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Số dư Thu trừ Chi (Net Balance)
                          Text(
                            'Số dư',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                          Text(
                            currencyFormatter.format(state.netBalance),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: state.netBalance < 0 ? Colors.pink.shade400 : Colors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Widget 2 Khối Thu/Chi
                          SummaryCardsWidget(
                            income: state.totalIncome,
                            expense: state.totalExpense,
                          ),
                          const SizedBox(height: 24),

                          // Biểu đồ Cột
                          BarChartWidget(dailyExpenses: state.dailyExpenses),
                          
                          // TODO: Danh sách phần trăm danh mục bên dưới biểu đồ
                        ],
                      ),
                    ),
                  );
                }
                return const Center(child: Text('Không có dữ liệu'));
              },
            ),
          ),
        ],
      ),
    );
  }
}