import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/account_model.dart';
import '../state/account_cubit.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/transactions/data/models/transaction_model.dart';
import '../../../../features/transactions/presentation/state/transaction_cubit.dart';

// --- 1. Form Chỉnh sửa tài khoản (Yêu cầu 3) ---
class EditAccountForm extends StatefulWidget {
  final AccountModel account;
  const EditAccountForm({super.key, required this.account});

  @override
  State<EditAccountForm> createState() => _EditAccountFormState();
}

class _EditAccountFormState extends State<EditAccountForm> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _descController = TextEditingController(text: widget.account.description ?? '');
    _selectedIcon = widget.account.icon ?? 'wallet';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chỉnh sửa tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên tài khoản', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final updatedAccount = AccountModel(
                  id: widget.account.id,
                  name: _nameController.text,
                  balance: widget.account.balance,
                  description: _descController.text,
                  icon: _selectedIcon,
                );
                context.read<AccountCubit>().updateAccount(updatedAccount);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF)),
              child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- 2. Form Điều chỉnh số dư (Yêu cầu 4) ---
class AdjustBalanceForm extends StatefulWidget {
  final AccountModel account;
  const AdjustBalanceForm({super.key, required this.account});

  @override
  State<AdjustBalanceForm> createState() => _AdjustBalanceFormState();
}

// --- 3. Form Chuyển khoản (Yêu cầu 8) ---
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
    // Lấy danh sách ví từ AccountCubit, loại bỏ ví nguồn hiện tại ra khỏi danh sách đích
    final accountState = context.read<AccountCubit>().state;
    List<AccountModel> targetAccounts = [];
    if (accountState is AccountLoaded) {
      targetAccounts = accountState.accounts.where((acc) => acc.id != widget.sourceAccount.id).toList();
    }

    // Xử lý lỗ hổng: Nếu chỉ có 1 ví thì không thể chuyển khoản
    if (targetAccounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Bạn cần tạo thêm ít nhất 1 tài khoản nữa để chuyển khoản.', 
          style: TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
      );
    }

    _targetAccountId ??= targetAccounts.first.id;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
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
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Số tiền', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.note), border: OutlineInputBorder()),
          ),
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
                  accountId: widget.sourceAccount.id,
                  toAccountId: _targetAccountId,
                  category: 'Chuyển tiền',
                  type: 'transfer',
                  amount: amount,
                  note: _noteController.text.isEmpty ? 'Chuyển sang $targetAccName' : _noteController.text,
                  date: DateTime.now().toIso8601String(),
                  offlineId: const Uuid().v4(),
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

class _AdjustBalanceFormState extends State<AdjustBalanceForm> {
  final _balanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Điều chỉnh số dư: ${widget.account.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Số dư thực tế',
              hintText: 'Hiện tại: ${widget.account.balance}',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
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
