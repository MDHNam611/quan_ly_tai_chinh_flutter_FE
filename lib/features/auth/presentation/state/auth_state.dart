abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userName;
  final String? photoUrl; // 👉 ĐÃ THÊM: Mảnh ghép để chứa link Avatar

  // Cập nhật constructor, biến photoUrl nằm trong ngoặc nhọn {} nghĩa là không bắt buộc (tùy chọn)
  AuthAuthenticated(this.userName, {this.photoUrl}); 
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}