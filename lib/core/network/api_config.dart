import 'dart:io';

class ApiConfig {
  // Trả về Base URL đúng tùy theo môi trường chạy
  static String get baseUrl {
    if (Platform.isAndroid) {
      // 10.0.2.2 là localhost của máy tính host nhìn từ máy ảo Android
      return 'http://10.0.2.2:3000/api/v1';
    } else if (Platform.isIOS) {
      // iOS Simulator sử dụng localhost bình thường
      return 'http://localhost:3000/api/v1';
    }
    // Dành cho Web hoặc Desktop
    return 'http://localhost:3000/api/v1'; 
  }
}