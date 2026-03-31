import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ĐÃ THÊM THƯ VIỆN BẢO MẬT INPUT
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/data/models/account_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/models/transaction_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';

// =========================================================
// 1. FORM THÊM / SỬA / XÓA TÀI KHOẢN (AccountActionForm)
// =========================================================
class AccountActionForm extends StatefulWidget {
  final AccountModel? account;
  const AccountActionForm({super.key, this.account});

  @override
  State<AccountActionForm> createState() => _AccountActionFormState();
}

class _AccountActionFormState extends State<AccountActionForm> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _descController = TextEditingController(text: widget.account?.description ?? '');
    _selectedIcon = widget.account?.icon ?? 'account_balance_wallet';
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (widget.account == null) {
      context.read<AccountCubit>().addAccount(name, _descController.text, _selectedIcon);
    } else {
      final updatedAccount = AccountModel(
        id: widget.account!.id,
        name: name,
        balance: widget.account!.balance,
        description: _descController.text,
        icon: _selectedIcon,
      );
      context.read<AccountCubit>().updateAccount(updatedAccount);
    }
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cảnh báo xóa', style: TextStyle(color: Colors.red)),
        content: const Text('Việc xóa tài khoản này sẽ xóa VĨNH VIỄN toàn bộ giao dịch liên quan đến nó.\n\nBạn có chắc chắn muốn xóa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              context.read<AccountCubit>().deleteAccount(widget.account!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    final Map<String, IconData> walletIcons = CategoryHelper.categorizedIcons['Ví & Ngân hàng'] ?? {};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? 'Chỉnh sửa tài khoản' : 'Thêm tài khoản mới', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameController, autofocus: !isEditing, decoration: const InputDecoration(labelText: 'Tên tài khoản', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Mô tả (Tùy chọn)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const Text('Chọn Biểu tượng:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: walletIcons.length,
              itemBuilder: (context, index) {
                final iconKey = walletIcons.keys.elementAt(index);
                final isSelected = _selectedIcon == iconKey;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconKey),
                  child: Container(
                    decoration: BoxDecoration(color: isSelected ? const Color(0xFFD6C4FF) : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.purple : Colors.grey.shade300)),
                    child: Icon(CategoryHelper.getIcon(iconKey), color: isSelected ? Colors.purple : Colors.grey),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (isEditing) Expanded(child: OutlinedButton(onPressed: _confirmDelete, style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Xóa'))),
              if (isEditing) const SizedBox(width: 16),
              Expanded(flex: 2, child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF), padding: const EdgeInsets.symmetric(vertical: 14)), child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo tài khoản', style: const TextStyle(color: Colors.black)))),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =========================================================
// 2. FORM ĐIỀU CHỈNH SỐ DƯ (AdjustBalanceForm)
// =========================================================
class AdjustBalanceForm extends StatefulWidget {
  final AccountModel account;
  const AdjustBalanceForm({super.key, required this.account});

  @override
  State<AdjustBalanceForm> createState() => _AdjustBalanceFormState();
}

class _AdjustBalanceFormState extends State<AdjustBalanceForm> {
  final _balanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Điều chỉnh số dư: ${widget.account.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController, keyboardType: TextInputType.number, autofocus: true,
            decoration: InputDecoration(labelText: 'Số dư thực tế', hintText: 'Hiện tại: ${widget.account.balance}', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.attach_money)),
            // ĐÃ THÊM: Chặn không cho nhập chữ và khóa cứng 13 số
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final cleanAmount = _balanceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final newBalance = double.tryParse(cleanAmount) ?? 0.0;
                context.read<AccountCubit>().adjustBalance(widget.account.id, newBalance);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF)),
              child: const Text('Cập nhật', style: TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// =========================================================
// 3. FORM CHUYỂN KHOẢN (TransferAccountForm)
// =========================================================
class TransferAccountForm extends StatefulWidget {
  final AccountModel sourceAccount;
  const TransferAccountForm({super.key, required this.sourceAccount});

  @override
  State<TransferAccountForm> createState() => _TransferAccountFormState();
}

class _TransferAccountFormState extends State<TransferAccountForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _targetAccountId;

  @override
  Widget build(BuildContext context) {
    final accountState = context.read<AccountCubit>().state;
    List<AccountModel> targetAccounts = [];
    if (accountState is AccountLoaded) {
      targetAccounts = accountState.accounts.where((acc) => acc.id != widget.sourceAccount.id).toList();
    }

    if (targetAccounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Bạn cần tạo thêm ít nhất 1 tài khoản nữa để chuyển khoản.', style: TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
      );
    }

    _targetAccountId ??= targetAccounts.first.id;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chuyển từ: ${widget.sourceAccount.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _targetAccountId,
            items: targetAccounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
            onChanged: (val) => setState(() => _targetAccountId = val),
            decoration: const InputDecoration(labelText: 'Chuyển đến ví', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController, keyboardType: TextInputType.number, autofocus: true, 
            decoration: const InputDecoration(labelText: 'Số tiền', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
            // ĐÃ THÊM: Chặn không cho nhập chữ và khóa cứng 13 số
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.note), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final amount = double.tryParse(cleanAmount) ?? 0.0;
                if (amount <= 0) return;

                final targetAccName = targetAccounts.firstWhere((a) => a.id == _targetAccountId).name;
                final tx = TransactionModel(
                  accountId: widget.sourceAccount.id, toAccountId: _targetAccountId, category: 'Chuyển tiền', type: 'transfer', amount: amount,
                  note: _noteController.text.isEmpty ? 'Chuyển sang $targetAccName' : _noteController.text, date: DateTime.now().toIso8601String(), offlineId: const Uuid().v4(),
                );

                context.read<TransactionCubit>().addTransaction(tx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF)),
              child: const Text('Xác nhận chuyển', style: TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}