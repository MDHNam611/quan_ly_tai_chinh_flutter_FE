import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ĐÃ THÊM: Để đọc dữ liệu lưu trong máy
import 'package:do_an_quan_ly_tai_chinh/features/auth/data/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;

  AuthCubit({required this.authService}) : super(AuthInitial());

  // Kiểm tra xem đã từng đăng nhập trước đó chưa (Lúc mới mở app)
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    final token = await authService.getToken();
    if (token != null) {
      // Đọc tên người dùng từ bộ nhớ đệm
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Người dùng';
      
      emit(AuthAuthenticated(userName)); 
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // ĐĂNG KÝ
  Future<void> register(String name, String email, String password) async {
    emit(AuthLoading());
    final error = await authService.register(name, email, password);
    if (error == null) {
      // Đăng ký thành công thì tự động gọi Đăng nhập
      await login(email, password);
    } else {
      emit(AuthError(error));
    }
  }

  // ĐĂNG NHẬP
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final error = await authService.login(email, password);
    
    if (error == null) {
      // ĐĂNG NHẬP THÀNH CÔNG: Lấy tên từ SharedPreferences (do AuthService vừa lưu vào)
      final prefs = await SharedPreferences.getInstance();
      String userName = prefs.getString('user_name') ?? '';
      
      // LOGIC THEO YÊU CẦU: Nếu tên trống, tự động cắt lấy phần username của email (trước ký tự @)
      if (userName.trim().isEmpty) {
        userName = email.split('@')[0];
      }

      emit(AuthAuthenticated(userName)); 
    } else {
      emit(AuthError(error));
    }
  }

  // ĐĂNG XUẤT
  Future<void> logout() async {
    emit(AuthLoading());
    await authService.logout();
    emit(AuthUnauthenticated());
  }
  // ĐĂNG NHẬP BẰNG GOOGLE
  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    final error = await authService.loginWithGoogle();
    
    if (error == null) {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Người dùng Google';
      emit(AuthAuthenticated(userName)); 
    } else {
      emit(AuthError(error));
    }
  }
}