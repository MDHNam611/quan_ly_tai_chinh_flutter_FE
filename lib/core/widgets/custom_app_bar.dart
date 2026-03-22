import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/pages/about_page.dart'; // Sẽ báo lỗi đỏ tạm thời vì ta chưa tạo file này

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions; // Chứa các nút bên phải (Ví dụ: Kính lúp, Dấu cộng)
  final Color backgroundColor;

  const CustomAppBar({
    super.key, 
    this.actions, 
    this.backgroundColor = Colors.white, // Mặc định là nền trắng
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.account_circle_outlined, color: Colors.black87, size: 28),
        onPressed: () {
          // Gọi Menu Đăng nhập / Giới thiệu
          ProfileMenu.show(context);
        },
      ),
      title: Column(
        children: [
          const Text('Tất cả các tài khoản', style: TextStyle(color: Colors.black54, fontSize: 12)),
          BlocBuilder<AccountCubit, AccountState>(
            builder: (context, state) {
              double totalBalance = 0;
              if (state is AccountLoaded) {
                for (var acc in state.accounts) totalBalance += acc.balance;
              }
              return Text(
                currencyFormatter.format(totalBalance), 
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}