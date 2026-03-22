import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/models/transaction_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';

class TransactionActionModal {
  // 1. MENU CHÍNH 
  static void showOptions(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.blue),
              title: const Text('Thay đổi ngày'),
              onTap: () {
                Navigator.pop(ctx);
                _showDateSelection(context, tx); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.teal),
              title: const Text('Thay đổi tài khoản'),
              onTap: () {
                Navigator.pop(ctx);
                _showAccountSelection(context, tx); // Gọi hàm mới thêm
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.orange),
              title: const Text('Thay đổi danh mục'),
              onTap: () {
                Navigator.pop(ctx);
                _showCategorySelection(context, tx); // Gọi hàm mới thêm
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa giao dịch', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, tx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 2. GIAO DIỆN CHỌN NGÀY (Giữ nguyên)
  static void _showDateSelection(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ngày', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final pickedDate = await showDatePicker(context: context, initialDate: DateTime.parse(tx.date), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (pickedDate != null && context.mounted) context.read<TransactionCubit>().updateTransactionDate(tx.offlineId, pickedDate);
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Column(children: [Icon(Icons.calendar_month, color: Colors.black54), SizedBox(height: 4), Text('Chọn ngày', style: TextStyle(fontWeight: FontWeight.w500))]),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<TransactionCubit>().updateTransactionDate(tx.offlineId, DateTime.now().subtract(const Duration(days: 1)));
                      },
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.nightlight_round, color: Colors.black54), SizedBox(height: 4), Text('Hôm qua', style: TextStyle(fontWeight: FontWeight.w500))])),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<TransactionCubit>().updateTransactionDate(tx.offlineId, DateTime.now());
                      },
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.wb_sunny, color: Colors.black), SizedBox(height: 4), Text('Hôm nay', style: TextStyle(fontWeight: FontWeight.w500))])),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // 3. GIAO DIỆN CHỌN TÀI KHOẢN (Yêu cầu 5)
  static void _showAccountSelection(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final accountState = context.read<AccountCubit>().state;
        if (accountState is! AccountLoaded) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Từ tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...accountState.accounts.map((acc) {
                final isSelected = acc.id == tx.accountId;
                return ListTile(
                  leading: Icon(CategoryHelper.getIcon(acc.icon ?? 'wallet'), color: isSelected ? Colors.teal : Colors.grey),
                  title: Text(acc.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<TransactionCubit>().updateTransactionAccount(tx, acc.id);
                    // Ép cập nhật lại số dư trên Header
                    context.read<AccountCubit>().loadAccounts(); 
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 4. GIAO DIỆN CHỌN DANH MỤC (Yêu cầu 6)
  static void _showCategorySelection(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final categoryState = context.read<CategoryCubit>().state;
        if (categoryState is! CategoryLoaded) return const SizedBox();

        // Chỉ hiển thị các danh mục cùng loại (Thu hoặc Chi) với giao dịch hiện tại
        final categories = tx.type == 'expense' ? categoryState.expenseCategories : categoryState.incomeCategories;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tx.type == 'expense' ? 'Chọn Danh mục Chi phí' : 'Chọn Danh mục Thu nhập', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 24, childAspectRatio: 0.75),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat.name == tx.category;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<TransactionCubit>().updateTransactionCategory(tx.offlineId, cat.name);
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: isSelected ? CategoryHelper.getColor(cat.color) : CategoryHelper.getColor(cat.color).withOpacity(0.15),
                            child: Icon(CategoryHelper.getIcon(cat.icon), color: isSelected ? Colors.white : CategoryHelper.getColor(cat.color), size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(cat.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 5. XÁC NHẬN XÓA (Giữ nguyên)
  static void _confirmDelete(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch?', style: TextStyle(color: Colors.red)),
        content: const Text('Số tiền của giao dịch này sẽ được hoàn lại vào ví của bạn. Bạn có chắc chắn muốn xóa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              context.read<TransactionCubit>().deleteTransactionSecure(tx);
              context.read<AccountCubit>().loadAccounts(); 
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}