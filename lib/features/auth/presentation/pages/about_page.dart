import 'package:flutter/material.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/pages/auth_page.dart'; // Sẽ báo lỗi đỏ tạm thời

// ========================================================
// HÀM HIỂN THỊ MENU BOTTOM SHEET KHI BẤM VÀO AVATAR
// ========================================================
class ProfileMenu {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8EAF6), child: Icon(Icons.cloud_sync, color: Colors.blue)),
                title: const Text('Đăng nhập / Đồng bộ', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Sao lưu dữ liệu lên đám mây'),
                onTap: () {
                  Navigator.pop(ctx); // Đóng menu
                  // Mở trang Đăng nhập
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFCE4EC), child: Icon(Icons.info_outline, color: Colors.pink)),
                title: const Text('Giới thiệu ứng dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx); // Đóng menu
                  // Mở trang Giới thiệu
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================
// TRANG GIỚI THIỆU ỨNG DỤNG
// ========================================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Giới thiệu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFD6C4FF).withOpacity(0.3), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(height: 24),
            const Text('Quản Lý Tài Chính', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Phiên bản 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            const Text(
              'Ứng dụng Quản Lý Tài Chính giúp bạn ghi chép, theo dõi và phân tích các luồng thu chi cá nhân một cách trực quan và hiệu quả nhất. '
              'Với khả năng đồng bộ đám mây, dữ liệu của bạn luôn được bảo mật và an toàn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 48),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.developer_mode, color: Colors.grey),
              title: Text('Nhà phát triển'),
              subtitle: Text('Nhóm Đồ Án / ĐH HUTECH'),
            ),
          ],
        ),
      ),
    );
  }
}