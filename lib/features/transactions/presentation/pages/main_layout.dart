import 'package:flutter/material.dart';
import '../../../../features/dashboard/presentation/page/dashboard_page.dart';
import '../../../../features/transactions/presentation/pages/transaction_page.dart';
// Import thêm AccountPage
import '../../../../features/accounts/presentation/pages/account_page.dart';

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
    const Scaffold(body: Center(child: Text('Màn hình Danh mục (Sẽ làm sau)'))),
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
        type: BottomNavigationBarType.fixed, // Quan trọng: Ép hiển thị đủ 4 tab không bị giật/ẩn
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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