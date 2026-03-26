import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Đổi màu sắc, đọc dữ liệu lưu trong máy
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
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Người dùng';
      
      // 👉 ĐÃ THÊM: Đọc link ảnh từ bộ nhớ đệm
      final photoUrl = prefs.getString('user_avatar');
      
      emit(AuthAuthenticated(userName, photoUrl: photoUrl)); 
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // ĐĂNG KÝ
  Future<void> register(String name, String email, String password) async {
    emit(AuthLoading());
    final error = await authService.register(name, email, password);
    if (error == null) {
      await login(email, password);
    } else {
      emit(AuthError(error));
    }
  }

  // ĐĂNG NHẬP (Bằng Email/Password thông thường)
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final error = await authService.login(email, password);
    
    if (error == null) {
      final prefs = await SharedPreferences.getInstance();
      String userName = prefs.getString('user_name') ?? '';
      
      if (userName.trim().isEmpty) {
        userName = email.split('@')[0];
      }

      // 👉 ĐÃ THÊM: Đọc link ảnh (Dù đăng nhập thường có thể null, vẫn phải truyền vào để Reset ảnh cũ)
      final photoUrl = prefs.getString('user_avatar');

      emit(AuthAuthenticated(userName, photoUrl: photoUrl)); 
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
      
      // 👉 ĐÃ THÊM: Đọc link ảnh do AuthService vừa lưu vào
      final photoUrl = prefs.getString('user_avatar');

      emit(AuthAuthenticated(userName, photoUrl: photoUrl)); 
    } else {
      emit(AuthError(error));
    }
  }
}