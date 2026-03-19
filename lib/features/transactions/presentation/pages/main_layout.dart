import 'package:flutter/material.dart';
import '../../../../features/dashboard/presentation/page/dashboard_page.dart';
import '../../../../features/transactions/presentation/pages/transaction_page.dart';
// Import thêm AccountPage
import '../../../../features/accounts/presentation/pages/account_page.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/pages/category_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Bắt buộc để dùng được hàm context.read()
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/dashboard/presentation/state/dashboard_cubit.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0; // Mặc định mở tab Tài khoản (Index 0)

  // Sắp xếp 4 màn hình theo thứ tự: Tài khoản, Danh mục, Giao dịch, Tổng quan
  final List<Widget> _pages = [
    const AccountPage(),
    const CategoryPage(),
    const TransactionPage(),
    const DashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Thêm 3 dòng này để ép làm mới dữ liệu mỗi khi chạm vào Tab
          if (index == 0) context.read<AccountCubit>().loadAccounts();
          if (index == 2) context.read<TransactionCubit>().loadTransactions();
          if (index == 3) {
            // Mở khóa dòng này để Dashboard cập nhật real-time theo tháng hiện tại
            context.read<DashboardCubit>().loadDashboardData(DateTime.now());
          }
          // Cập nhật lại biểu đồ Tổng quan theo tháng hiện tại đang chọn
          // if (index == 3) context.read<DashboardCubit>().loadDashboardData(DateTime.now()); 
        },
        selectedItemColor: const Color(0xFFD6C4FF), // Màu tím theo thiết kế
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Tài khoản'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Danh mục'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Giao dịch'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tổng quan'),
        ],
      ),
    );
  }
}