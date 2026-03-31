import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:do_an_quan_ly_tai_chinh/injection_container.dart' as di;
import 'package:do_an_quan_ly_tai_chinh/features/auth/data/services/auth_service.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/state/auth_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/state/auth_state.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/core/helpers/database_helper.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true; 
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; 

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); 
  final _nameController = TextEditingController();

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (!_isLogin) {
      if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
      if (!value.contains(RegExp(r'[A-Z]'))) return 'Phải chứa ít nhất 1 chữ cái viết hoa (A-Z)';
      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Phải chứa ít nhất 1 ký tự đặc biệt';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return; 

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim(); 
    final name = _nameController.text.trim();

    if (_isLogin) {
      context.read<AuthCubit>().login(email, password);
    } else {
      context.read<AuthCubit>().register(name, email, password);
    }
  }

  // =========================================================
  // GIAO DIỆN & LOGIC QUÊN MẬT KHẨU
  // =========================================================
  void _showForgotPasswordDialog() {
    final forgotEmailController = TextEditingController(text: _emailController.text);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Quên mật khẩu?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Vui lòng nhập email tài khoản của bạn để nhận mã xác thực OTP.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: forgotEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final email = forgotEmailController.text.trim();
                  if (email.isEmpty) return;

                  setStateModal(() => isLoading = true);
                  try {
                    final baseUrl = di.sl<AuthService>().baseUrl; // Lấy URL từ service
                    final response = await http.post(
                      Uri.parse('$baseUrl/forgot-password'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'email': email}),
                    );
                    
                    final resData = jsonDecode(response.body);
                    if (response.statusCode == 200) {
                      Navigator.pop(ctx); // Tắt form nhập mail
                      _showResetPasswordDialog(email); // Mở form nhập OTP
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(resData['message'] ?? 'Lỗi'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Không thể kết nối máy chủ'), backgroundColor: Colors.red));
                  } finally {
                    setStateModal(() => isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
                child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Gửi mã OTP', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPasswordDialog(String email) {
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Đổi mật khẩu mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mã OTP đã được gửi tới $email. Mã có hiệu lực trong 5 phút.', style: const TextStyle(color: Colors.green, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Mã OTP (6 số)',
                      prefixIcon: const Icon(Icons.security),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Yêu cầu: >= 8 ký tự, 1 chữ HOA, 1 ký tự đặc biệt.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isResetting ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isResetting ? null : () async {
                  setStateModal(() => isResetting = true);
                  try {
                    final baseUrl = di.sl<AuthService>().baseUrl;
                    final response = await http.post(
                      Uri.parse('$baseUrl/reset-password'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'email': email,
                        'otp': otpController.text.trim(),
                        'newPassword': newPassController.text.trim()
                      }),
                    );
                    
                    final resData = jsonDecode(response.body);
                    if (response.statusCode == 200) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resData['message']), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(resData['message'] ?? 'Lỗi'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Lỗi kết nối máy chủ'), backgroundColor: Colors.red));
                  } finally {
                    setStateModal(() => isResetting = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
                child: isResetting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Xác nhận đổi', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  // HÀM IMPORT DỮ LIỆU...
  Future<void> _importDataToSQLite(Map<String, dynamic> cloudData) async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('accounts');
    await db.delete('categories');
    await db.delete('transactions');

    for (var acc in cloudData['accounts'] ?? []) {
      await db.insert('accounts', {
        'id': acc['id'], 'name': acc['name'], 'balance': acc['balance'],
        'description': acc['description'], 'icon': acc['icon'],
      });
    }

    for (var cat in cloudData['categories'] ?? []) {
      await db.insert('categories', {
        'id': cat['id'], 'name': cat['name'], 'type': cat['type'],
        'icon': cat['icon'], 'color': cat['color'],
      });
    }

    for (var tx in cloudData['transactions'] ?? []) {
      await db.insert('transactions', {
        'mongoId': tx['_id'], 'offlineId': tx['offlineId'], 
        'accountId': tx['accountId'], 'toAccountId': tx['toAccountId'], 
        'category': tx['category'], 'type': tx['type'],
        'amount': tx['amount'], 'note': tx['note'],
        'date': tx['date'], 'isSynced': 1, 
      });
    }

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
            showDialog(
              context: context, barrierDismissible: false,
              builder: (c) => const Center(child: CircularProgressIndicator()),
            );

            try {
              final authService = di.sl<AuthService>();
              final cloudData = await authService.pullData();

              if (cloudData != null) {
                await _importDataToSQLite(cloudData);
              }
              
              if (context.mounted) {
                Navigator.pop(context); 
                Navigator.pop(context); 
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
            child: Form(
              key: _formKey,
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
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập email' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
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
                    validator: _validatePassword, 
                  ),

                  // 👉 ĐÃ THÊM: Nút Quên mật khẩu (Chỉ hiện khi đang ở tab Đăng nhập)
                  if (_isLogin) 
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : _showForgotPasswordDialog,
                        child: const Text('Quên mật khẩu?', style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !isLoading,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                        if (value != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : () {
                        context.read<AuthCubit>().loginWithGoogle();
                      },
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
                        onTap: isLoading ? null : () {
                          _formKey.currentState?.reset(); 
                          _passwordController.clear();
                          _confirmPasswordController.clear(); 
                          setState(() => _isLogin = !_isLogin);
                        },
                        child: Text(
                          _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                          style: TextStyle(color: isLoading ? Colors.grey : const Color(0xFF3F51B5), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}