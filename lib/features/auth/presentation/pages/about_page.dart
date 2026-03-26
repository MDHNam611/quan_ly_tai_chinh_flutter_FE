import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/pages/auth_page.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/state/auth_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/state/auth_state.dart';

import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/data/services/auth_service.dart';
import 'package:do_an_quan_ly_tai_chinh/injection_container.dart' as di;

// ========================================================
// HÀM HIỂN THỊ MENU KHI BẤM VÀO ICON AVATAR
// ========================================================
class ProfileMenu {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final bool isAuth = authState is AuthAuthenticated;
          final String userName = isAuth ? authState.userName : '';
          
          // 👉 ĐÃ THÊM: Lấy link avatar từ State (Ép kiểu an toàn)
          final String? photoUrl = isAuth ? (authState).photoUrl : null; 

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  
                  if (isAuth) ...[
                    ListTile(
                      // 👉 ĐÃ CẬP NHẬT: Hiện Avatar nếu có link, nếu null thì hiện icon mặc định
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE8EAF6),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null ? const Icon(Icons.person, color: Colors.blue) : null,
                      ),
                      title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text('Đã kết nối với đám mây', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ),
                    const Divider(),
                    
                    // =========================================================
                    // NÚT ĐỒNG BỘ (ĐÃ FIX LỖI CONTEXT VÀ DEAD CODE)
                    // =========================================================
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFF3E5F5), child: Icon(Icons.cloud_upload, color: Colors.teal)),
                      title: const Text('Đồng bộ dữ liệu ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () async {
                        // 1. Lưu tham chiếu trước khi thao tác bất đồng bộ
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        // Đóng menu BottomSheet
                        navigator.pop(); 

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final accState = context.read<AccountCubit>().state;
                          final catState = context.read<CategoryCubit>().state;
                          final txState = context.read<TransactionCubit>().state;

                          List<Map<String, dynamic>> accountsJson = [];
                          if (accState is AccountLoaded) {
                            accountsJson = accState.accounts.map((e) => {
                              'id': e.id, 'name': e.name, 'balance': e.balance,
                              'icon': e.icon, 'description': e.description,
                            }).toList();
                          }

                          List<Map<String, dynamic>> categoriesJson = [];
                          if (catState is CategoryLoaded) {
                            final allCats = [...catState.expenseCategories, ...catState.incomeCategories];
                            categoriesJson = allCats.map((e) => {
                              'id': e.name, 'name': e.name, 'type': e.type, 'icon': e.icon, 'color': e.color,
                            }).toList();
                          }

                          List<Map<String, dynamic>> transactionsJson = [];
                          if (txState is TransactionLoaded) {
                            transactionsJson = txState.transactions.map((e) => {
                              'offlineId': e.offlineId,
                              'accountId': e.accountId, 'toAccountId': e.toAccountId,
                              'category': e.category, 'type': e.type,
                              'amount': e.amount, 'note': e.note, 'date': e.date,
                            }).toList();
                          }

                          final authService = di.sl<AuthService>();
                          final error = await authService.syncData(accountsJson, categoriesJson, transactionsJson);

                          // 2. Tắt màn hình Loading bằng navigator đã lưu
                          if (navigator.canPop()) navigator.pop(); 

                          // 3. Hiện thông báo bằng messenger đã lưu
                          if (error == null) {
                            messenger.showSnackBar(const SnackBar(content: Text('Đồng bộ lên đám mây thành công! ☁️'), backgroundColor: Colors.green));
                          } else {
                            messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                          }
                        } catch (e) {
                          if (navigator.canPop()) navigator.pop();
                          messenger.showSnackBar(SnackBar(content: Text('Lỗi ngoại lệ: $e'), backgroundColor: Colors.red));
                        }
                      },
                    ),
                  ] 
                  else ...[
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFE8EAF6), child: Icon(Icons.cloud_sync, color: Colors.blue)),
                      title: const Text('Đăng nhập / Đồng bộ', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Sao lưu dữ liệu lên đám mây'),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
                      },
                    ),
                  ],

                  const Divider(),

                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFFCE4EC), child: Icon(Icons.info_outline, color: Colors.pink)),
                    title: const Text('Giới thiệu ứng dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                    },
                  ),

                  if (isAuth) ...[
                    const Divider(),
                    // ==============================================================
                    // NÚT ĐĂNG XUẤT (ĐÃ FIX LỖI CONTEXT VÀ DEAD CODE)
                    // ==============================================================
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.transparent, child: Icon(Icons.logout, color: Colors.red)),
                      title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final authCubit = context.read<AuthCubit>();
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        navigator.pop(); // Đóng menu BottomSheet

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final accState = context.read<AccountCubit>().state;
                          final catState = context.read<CategoryCubit>().state;
                          final txState = context.read<TransactionCubit>().state;

                          List<Map<String, dynamic>> accountsJson = [];
                          if (accState is AccountLoaded) {
                            accountsJson = accState.accounts.map((e) => {
                              'id': e.id, 'name': e.name, 'balance': e.balance,
                              'icon': e.icon, 'description': e.description,
                            }).toList();
                          }

                          List<Map<String, dynamic>> categoriesJson = [];
                          if (catState is CategoryLoaded) {
                            final allCats = [...catState.expenseCategories, ...catState.incomeCategories];
                            categoriesJson = allCats.map((e) => {
                              'id': e.name, 'name': e.name, 'type': e.type, 'icon': e.icon, 'color': e.color,
                            }).toList();
                          }

                          List<Map<String, dynamic>> transactionsJson = [];
                          if (txState is TransactionLoaded) {
                            transactionsJson = txState.transactions.map((e) => {
                              'offlineId': e.offlineId,
                              'accountId': e.accountId, 'toAccountId': e.toAccountId,
                              'category': e.category, 'type': e.type,
                              'amount': e.amount, 'note': e.note, 'date': e.date,
                            }).toList();
                          }

                          final authService = di.sl<AuthService>();
                          final error = await authService.syncData(accountsJson, categoriesJson, transactionsJson);

                          if (navigator.canPop()) navigator.pop(); // Tắt Loading

                          if (error == null) {
                            authCubit.logout(); // Dùng authCubit đã lưu ở ngoài
                            messenger.showSnackBar(const SnackBar(content: Text('Đã lưu dữ liệu và Đăng xuất an toàn! ✅'), backgroundColor: Colors.green));
                          } else {
                            messenger.showSnackBar(SnackBar(content: Text('Sao lưu thất bại, hủy Đăng xuất để tránh mất dữ liệu: $error'), backgroundColor: Colors.red));
                          }

                        } catch (e) {
                          if (navigator.canPop()) navigator.pop();
                          messenger.showSnackBar(SnackBar(content: Text('Lỗi hệ thống, không thể Đăng xuất: $e'), backgroundColor: Colors.red));
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ========================================================
// TRANG GIỚI THIỆU ỨNG DỤNG
// ========================================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Giới thiệu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFD6C4FF).withOpacity(0.3), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(height: 24),
            const Text('Quản Lý Tài Chính', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Phiên bản 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            const Text(
              'Ứng dụng Quản Lý Tài Chính giúp bạn ghi chép, theo dõi và phân tích các luồng thu chi cá nhân một cách trực quan và hiệu quả nhất. '
              'Với khả năng đồng bộ đám mây, dữ liệu của bạn luôn được bảo mật và an toàn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 48),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.developer_mode, color: Colors.grey),
              title: Text('Nhà phát triển'),
              subtitle: Text('Mai Đức Hoàng Nam / ĐH HUTECH'),
            ),
          ],
        ),
      ),
    );
  }
}