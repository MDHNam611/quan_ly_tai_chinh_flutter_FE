import 'package:flutter/material.dart';

class CategoryHelper {
  // Từ điển ánh xạ chuỗi sang IconData
  static final Map<String, IconData> icons = {
    'wallet': Icons.account_balance_wallet,
    'payments': Icons.payments,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'favorite': Icons.favorite,
    'wifi': Icons.wifi,
    'home': Icons.home,
    'local_hospital': Icons.local_hospital,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'school': Icons.school,
    'fitness_center': Icons.fitness_center,
  };

  static IconData getIcon(String iconName) {
    return icons[iconName] ?? Icons.category;
  }

  // Chuyển mã màu Hex (VD: #FF0000) sang Color của Flutter
  static Color getColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Thêm độ đục (Opacity) mặc định là 100%
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}