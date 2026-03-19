import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceHelper {
  static const String _deviceIdKey = 'device_offline_id';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    // Nếu thiết bị chưa có ID (mở app lần đầu), tạo mới và lưu lại
    if (deviceId == null) {
      deviceId = 'device-${const Uuid().v4()}';
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }
}