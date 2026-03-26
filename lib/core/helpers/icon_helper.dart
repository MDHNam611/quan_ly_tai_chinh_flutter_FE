import 'package:flutter/material.dart';

class CategoryHelper {
  // =========================================================
  // 1. TỔNG KHO ICON MỚI (ĐÃ PHÂN NHÓM ĐỂ DÙNG CHO UI)
  // =========================================================
  static final Map<String, Map<String, IconData>> categorizedIcons = {
    'Ví & Ngân hàng': {
      'account_balance_wallet': Icons.account_balance_wallet,
      'account_balance': Icons.account_balance,
      'savings': Icons.savings,
      'credit_card': Icons.credit_card,
      'payments': Icons.payments,
      'assured_workload': Icons.assured_workload,
    },
    'Ăn uống': {
      'restaurant': Icons.restaurant,
      'fastfood': Icons.fastfood,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'cake': Icons.cake,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'breakfast_dining': Icons.breakfast_dining,
      'bakery_dining': Icons.bakery_dining,
      'icecream': Icons.icecream,
    },
    'Di chuyển': {
      'directions_car': Icons.directions_car,
      'two_wheeler': Icons.two_wheeler,
      'local_taxi': Icons.local_taxi,
      'flight': Icons.flight,
      'directions_bus': Icons.directions_bus,
      'train': Icons.train,
      'local_gas_station': Icons.local_gas_station,
      'parking': Icons.local_parking,
    },
    'Hóa đơn & Nhà cửa': {
      'home': Icons.home,
      'apartment': Icons.apartment,
      'electric_meter': Icons.electric_meter,
      'water_drop': Icons.water_drop,
      'wifi': Icons.wifi,
      'phone_android': Icons.phone_android,
      'tv': Icons.tv,
      'bolt': Icons.bolt,
    },
    'Mua sắm': {
      'shopping_bag': Icons.shopping_bag,
      'shopping_cart': Icons.shopping_cart,
      'checkroom': Icons.checkroom,
      'storefront': Icons.storefront,
      'sell': Icons.sell,
    },
    'Giải trí & Thể thao': {
      'movie': Icons.movie,
      'sports_esports': Icons.sports_esports,
      'fitness_center': Icons.fitness_center,
      'pool': Icons.pool,
      'sports_soccer': Icons.sports_soccer,
    },
    'Y tế & Giáo dục': {
      'medical_services': Icons.medical_services,
      'local_hospital': Icons.local_hospital,
      'medication': Icons.medication,
      'school': Icons.school,
      'menu_book': Icons.menu_book,
    },
    'Gia đình & Thu nhập': {
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'work': Icons.work,
      'trending_up': Icons.trending_up,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
    },
    'Khác': {
      'build': Icons.build,
      'more_horiz': Icons.more_horiz,
      'celebration': Icons.celebration,
      'groups': Icons.groups,
    },
  };

  // =========================================================
  // 2. BIẾN ICONS CŨ (Tự động gộp phẳng để giữ nguyên cấu trúc cũ)
  // =========================================================
  static final Map<String, IconData> icons = categorizedIcons.values.reduce((map1, map2) => {...map1, ...map2});

  // =========================================================
  // 3. CÁC HÀM CỐT LÕI (ĐƯỢC GIỮ NGUYÊN 100% THEO YÊU CẦU)
  // =========================================================

  // HÀM LẤY ICON TỪ TÊN (KEY)
  static IconData getIcon(String iconName) {
    return icons[iconName] ?? Icons.more_horiz; // Trả về dấu 3 chấm nếu không tìm thấy
  }

  // HÀM TẠO MÀU SẮC NGẪU NHIÊN CHO DANH MỤC (Dựa vào String)
  static Color getColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      case 'pink': return Colors.pink;
      case 'indigo': return Colors.indigo;
      case 'amber': return Colors.amber;
      case 'cyan': return Colors.cyan;
      case 'brown': return Colors.brown;
      default: return Colors.grey; 
    }
  }

  // HÀM TỰ ĐỘNG GÁN MÀU KHI TẠO DANH MỤC MỚI
  static String getRandomColorString() {
    final colors = ['red', 'blue', 'green', 'orange', 'purple', 'teal', 'pink', 'indigo', 'amber', 'cyan'];
    colors.shuffle(); // Xáo trộn ngẫu nhiên
    return colors.first;
  }
}