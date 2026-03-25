import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:do_an_quan_ly_tai_chinh/injection_container.dart' as di;
import 'package:do_an_quan_ly_tai_chinh/features/auth/data/services/auth_service.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/state/auth_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/state/auth_state.dart';

// ĐÃ THÊM: Import Cubit để làm mới dữ liệu sau khi Sync
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
// ĐÃ THÊM: Import DatabaseHelper từ file bạn cung cấp
import 'package:do_an_quan_ly_tai_chinh/core/helpers/database_helper.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true; 
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')));
      return;
    }

    if (_isLogin) {
      context.read<AuthCubit>().login(email, password);
    } else {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ tên')));
        return;
      }
      context.read<AuthCubit>().register(name, email, password);
    }
  }

  // HÀM XỬ LÝ DỮ LIỆU TỪ CLOUD ĐỔ VÀO SQLITE
  Future<void> _importDataToSQLite(Map<String, dynamic> cloudData) async {
    // Sử dụng instance singleton từ file database_helper.dart của bạn
    final db = await DatabaseHelper.instance.database;

    // 1. Xóa sạch dữ liệu cũ trong máy để tránh xung đột
    await db.delete('accounts');
    await db.delete('categories');
    await db.delete('transactions');

    // 2. Chèn mảng Accounts
    for (var acc in cloudData['accounts'] ?? []) {
      await db.insert('accounts', {
        'id': acc['id'],
        'name': acc['name'],
        'balance': acc['balance'],
        'description': acc['description'],
        'icon': acc['icon'],
      });
    }

    // 3. Chèn mảng Categories
    for (var cat in cloudData['categories'] ?? []) {
      await db.insert('categories', {
        'id': cat['id'],
        'name': cat['name'],
        'type': cat['type'],
        'icon': cat['icon'],
        'color': cat['color'],
      });
    }

    // 4. Chèn mảng Transactions
    for (var tx in cloudData['transactions'] ?? []) {
      await db.insert('transactions', {
        'mongoId': tx['_id'], // ID thực của MongoDB
        'offlineId': tx['offlineId'], // Giữ nguyên ID offline cũ
        'accountId': tx['accountId'],
        'toAccountId': tx['toAccountId'], 
        'category': tx['category'],
        'type': tx['type'],
        'amount': tx['amount'],
        'note': tx['note'],
        'date': tx['date'],
        'isSynced': 1, // Đánh dấu là dữ liệu này đã được đồng bộ
      });
    }

    // 5. Yêu cầu các Cubit đọc lại dữ liệu mới từ SQLite để cập nhật UI
    if (mounted) {
      context.read<AccountCubit>().loadAccounts();
      context.read<CategoryCubit>().loadCategories();
      context.read<TransactionCubit>().loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
          } 
          else if (state is AuthAuthenticated) {
            // HIỆN LOADING KHI BẮT ĐẦU PULL DỮ LIỆU
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(child: CircularProgressIndicator()),
            );

            try {
              // Gọi API lấy dữ liệu từ MongoDB
              final authService = di.sl<AuthService>();
              final cloudData = await authService.pullData();

              if (cloudData != null) {
                // Nhét dữ liệu vào SQLite
                await _importDataToSQLite(cloudData);
              }
              
              if (context.mounted) {
                Navigator.pop(context); // Tắt vòng xoay Loading
                Navigator.pop(context); // Đóng form Đăng nhập
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đăng nhập và Kéo dữ liệu về máy thành công! ☁️'), backgroundColor: Colors.green)
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đồng bộ: $e'), backgroundColor: Colors.red));
              }
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Chào mừng\ntrở lại!' : 'Tạo tài khoản\nmới',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Đăng nhập để đồng bộ dữ liệu.' : 'Bắt đầu hành trình quản lý tài chính.',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                // ==========================================
                // NÚT ĐĂNG NHẬP BẰNG GOOGLE
                // ==========================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : () {
                      context.read<AuthCubit>().loginWithGoogle();
                    },
                    // 👉 ĐÃ SỬA: Thay ảnh mạng bằng Icon có sẵn của Flutter
                    icon: const Icon(Icons.g_mobiledata, size: 36, color: Colors.red),
                    label: const Text(
                      'Tiếp tục với Google',
                      style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isLogin ? 'Đăng nhập' : 'Đăng ký',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? ', style: const TextStyle(color: Colors.grey)),
                    InkWell(
                      onTap: isLoading ? null : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                        style: TextStyle(color: isLoading ? Colors.grey : const Color(0xFF3F51B5), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}