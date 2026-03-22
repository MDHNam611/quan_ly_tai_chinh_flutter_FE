import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 

// Import các trang
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/pages/account_page.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/pages/category_page.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/pages/transaction_page.dart';
import 'package:do_an_quan_ly_tai_chinh/features/overview/presentation/page/overview_page.dart'; // ĐÃ SỬA: Import trang Overview mới

// Import các Cubit
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0; 

  // Sắp xếp 4 màn hình: Tài khoản, Danh mục, Giao dịch, Tổng quan (Overview)
  final List<Widget> _pages = [
    const AccountPage(),
    const CategoryPage(),
    const TransactionPage(),
    const OverviewPage(), // ĐÃ SỬA: Thay thế DashboardPage bằng OverviewPage
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
          
          // Ép làm mới dữ liệu khi chạm vào Tab Tài khoản hoặc Giao dịch
          if (index == 0) context.read<AccountCubit>().loadAccounts();
          if (index == 2) context.read<TransactionCubit>().loadTransactions();
          
          // LƯU Ý: Không ép load lại dữ liệu với DateTime.now() ở tab Overview nữa
          // Để OverviewPage tự quản lý trạng thái thời gian của nó qua IndexedStack
        },
        selectedItemColor: const Color(0xFFD6C4FF), 
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