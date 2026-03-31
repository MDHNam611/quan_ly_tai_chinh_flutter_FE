import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart'; 

class AuthService {
  // LƯU Ý: Nếu dùng máy ảo Android Studio, hãy đổi 'localhost' thành '10.0.2.2'
  // Nếu dùng máy thật, thay bằng IP IPv4 của máy tính bạn (VD: '192.168.1.5')
  final String baseUrl = 'https://api-quan-ly-tai-chinh.onrender.com/api/auth';

  // HÀM ĐĂNG KÝ
  Future<String?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        return null; // Thành công (không có lỗi)
      } else {
        return jsonDecode(response.body)['message'] ?? 'Lỗi không xác định';
      }
    } catch (e) {
      return 'Không thể kết nối đến máy chủ';
    }
  }

  // HÀM ĐĂNG NHẬP
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ĐĂNG NHẬP THÀNH CÔNG: Lưu Token vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_name', data['name']);
        return null; // Thành công
      } else {
        return data['message'] ?? 'Lỗi không xác định';
      }
    } catch (e) {
      return 'Không thể kết nối đến máy chủ';
    }
  }

  // HÀM LẤY TOKEN (Dùng để kiểm tra xem đã đăng nhập chưa)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // HÀM ĐĂNG XUẤT (ĐÃ THÊM LOGIC XÓA AVATAR)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    
    // 👉 ĐÃ THÊM: Xóa link avatar khỏi bộ nhớ đệm để tránh bị "bóng ma"
    await prefs.remove('user_avatar'); 
  }

  // HÀM ĐỒNG BỘ DỮ LIỆU LÊN MONGODB (PUSH)
  Future<String?> syncData(
      List<Map<String, dynamic>> accounts,
      List<Map<String, dynamic>> categories,
      List<Map<String, dynamic>> transactions) async {
    try {
      final token = await getToken();
      if (token == null) return 'Bạn chưa đăng nhập';

      // LƯU Ý: Đường dẫn này trùng với baseUrl của bạn, thay đổi IP nếu cần (10.0.2.2 cho máy ảo)
      final String syncUrl = baseUrl.replaceAll('/auth', '/sync/push');

      final response = await http.post(
        Uri.parse(syncUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gửi kèm token để xác thực
        },
        body: jsonEncode({
          'accounts': accounts,
          'categories': categories,
          'transactions': transactions,
        }),
      );

      if (response.statusCode == 200) {
        return null; // Đồng bộ thành công
      } else {
        return jsonDecode(response.body)['message'] ?? 'Lỗi đồng bộ từ server';
      }
    } catch (e) {
      return 'Không thể kết nối đến máy chủ: $e';
    }
  }

  // HÀM KÉO DỮ LIỆU TỪ MONGODB VỀ (PULL)
  Future<Map<String, dynamic>?> pullData() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final String pullUrl = baseUrl.replaceAll('/auth', '/sync/pull');

      final response = await http.get(
        Uri.parse(pullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Trả về thẳng object chứa 3 mảng: accounts, categories, transactions
        return jsonDecode(response.body); 
      } else {
        return null;
      }
    } catch (e) {
      print('Lỗi Pull Data: $e');
      return null;
    }
  }

  // ======================================================
  // HÀM ĐĂNG NHẬP BẰNG GOOGLE (ĐÃ CẬP NHẬT LƯU ẢNH)
  // ======================================================
  Future<String?> loginWithGoogle() async {
    try {
      // 1. Phải dùng GoogleSignIn.instance (Singleton)
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      
      // 2. Bắt buộc phải khởi tạo trước khi gọi auth
      await googleSignIn.initialize();
      
      // 3. Dùng hàm authenticate() thay cho signIn() cũ
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      
      if (googleUser == null) {
        return 'Đã hủy đăng nhập Google'; // Người dùng bấm nút Back
      }

      // Gửi thông tin lấy được từ Google lên Backend
      final String googleUrl = baseUrl.replaceAll('/auth', '/auth/google');
      final response = await http.post(
        Uri.parse(googleUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Người dùng Google',
          'googleId': googleUser.id,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Lưu token vào máy y như đăng nhập bình thường
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_name', data['name']);
        
        // 👉 ĐÃ THÊM: Lưu link ảnh Google vào máy (nếu có)
        if (googleUser.photoUrl != null) {
          await prefs.setString('user_avatar', googleUser.photoUrl!);
        }
        
        return null; // Thành công
      } else {
        // Đăng xuất khỏi Google nếu backend từ chối
        await googleSignIn.signOut();
        return data['message'] ?? 'Lỗi không xác định từ server';
      }
    } catch (e) {
      return 'Lỗi Google Sign-In: $e\n(Hãy đảm bảo bạn đã cấu hình file google-services.json)';
    }
  }
}