import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// Đảm bảo sử dụng cú pháp package: chuẩn xác
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/models/transaction_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/data/models/account_model.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});
  // Hàm dịch từ ID ví sang Tên ví
  String _getAccountName(String accountId, BuildContext context) {
    final accountState = context.read<AccountCubit>().state;
    if (accountState is AccountLoaded) {
      final account = accountState.accounts.firstWhere(
        (acc) => acc.id == accountId,
        orElse: () => AccountModel(id: '', name: 'Ví đã xóa', balance: 0, icon: 'wallet'), // Đề phòng ví bị xóa
      );
      return account.name;
    }
    return accountId;
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'HÔM NAY\n${date.day} THÁNG ${date.month} ${date.year}';
    } else if (dateToCheck == yesterday) {
      return 'HÔM QUA\n${date.day} THÁNG ${date.month} ${date.year}';
    }
    return '${DateFormat('EEEE', 'vi_VN').format(date).toUpperCase()}\n${date.day} THÁNG ${date.month} ${date.year}';
  }

  void _showAddTransactionModal(BuildContext parentContext) {
    // Cần lấy cả 2 Cubit để truyền vào BottomSheet
    final txCubit = parentContext.read<TransactionCubit>();
    final accCubit = parentContext.read<AccountCubit>();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: txCubit),
            BlocProvider.value(value: accCubit), // Cung cấp AccountCubit cho Form
          ],
          child: const AddTransactionForm(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Giao dịch',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TransactionError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          } else if (state is TransactionLoaded) {
            if (state.transactions.isEmpty) {
              return const Center(child: Text('Chưa có giao dịch. Bấm + để thêm.'));
            }

            return GroupedListView<TransactionModel, DateTime>(
              elements: state.transactions,
              groupBy: (tx) {
                final date = DateTime.parse(tx.date);
                return DateTime(date.year, date.month, date.day);
              },
              order: GroupedListOrder.DESC,
              useStickyGroupSeparators: true,
              groupSeparatorBuilder: (DateTime date) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade50,
                child: Text(
                  _formatHeaderDate(date),
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              itemBuilder: (context, tx) {
                final isExpense = tx.type == 'expense';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpense
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    child: Icon(
                      isExpense ? Icons.restaurant : Icons.account_balance_wallet,
                      color: isExpense ? Colors.blue : Colors.green,
                    ),
                  ),
                  title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          
                          // GIẢI PHÁP 1: Bọc Expanded để text tự động co rút lại không đâm thủng màn hình
                          Expanded(
                            child: Text(
                              // GIẢI PHÁP 2: Gọi hàm để hiển thị Tên ví thay vì ID dài ngoằng
                              _getAccountName(tx.accountId, context), 
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1, // Chỉ cho phép hiển thị 1 dòng
                              overflow: TextOverflow.ellipsis, // Tự động thêm dấu "..." nếu tên quá dài
                            ),
                          ),
                        ],
                      ),
                      if (tx.note.isNotEmpty)
                        // Bọc thêm cho ghi chú để đề phòng ghi chú quá dài cũng làm vỡ UI
                        Text(
                          tx.note,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Text(
                    '${isExpense ? '-' : '+'}${currencyFormatter.format(tx.amount)}',
                    style: TextStyle(
                      color: isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD6C4FF),
        onPressed: () => _showAddTransactionModal(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class AddTransactionForm extends StatefulWidget {
  final String? initialAccountId;
  final String? initialType;
  final String? initialCategory;

  const AddTransactionForm({
    super.key,
    this.initialAccountId,
    this.initialType,
    this.initialCategory,
  });

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _type;
  late String _category;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'expense';
    _category = widget.initialCategory ?? 'Đồ ăn';
    _accountId = widget.initialAccountId;
  }

  void _save() {
    if (_amountController.text.isEmpty || _accountId == null) return;

    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount <= 0) return;

    final newTx = TransactionModel(
      accountId: _accountId!,
      category: _category,
      type: _type,
      amount: amount,
      note: _noteController.text,
      date: DateTime.now().toIso8601String(),
      offlineId: const Uuid().v4(),
      isSynced: 0,
    );

    // 1. Lưu giao dịch
    context.read<TransactionCubit>().addTransaction(newTx);
    
    // 2. Load lại số dư các ví để UI cập nhật ngay lập tức
    context.read<AccountCubit>().loadAccounts();
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách tài khoản từ State
    final accountState = context.read<AccountCubit>().state;
    List<AccountModel> accounts = [];
    if (accountState is AccountLoaded) {
      accounts = accountState.accounts;
    }

    // Xử lý an toàn: Nếu chưa chọn ví hoặc ví truyền vào bị xóa mất
    if (accounts.isNotEmpty) {
      if (_accountId == null || !accounts.any((a) => a.id == _accountId)) {
        _accountId = accounts.first.id;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thêm giao dịch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'expense',
                      groupValue: _type,
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const Text('Chi'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'income',
                      groupValue: _type,
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const Text('Thu'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Dropdown Tài khoản động
          if (accounts.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _accountId,
              items: accounts.map((acc) {
                return DropdownMenuItem(value: acc.id, child: Text(acc.name));
              }).toList(),
              onChanged: (val) => setState(() => _accountId = val),
              decoration: const InputDecoration(labelText: 'Tài khoản', border: OutlineInputBorder()),
            )
          else
            const Text('Vui lòng tạo tài khoản trước', style: TextStyle(color: Colors.red)),
            
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: _category,
            items: const [
              DropdownMenuItem(value: 'Đồ ăn', child: Text('Đồ ăn')),
              DropdownMenuItem(value: 'Di chuyển', child: Text('Di chuyển')),
              DropdownMenuItem(value: 'Giải trí', child: Text('Giải trí')),
              DropdownMenuItem(value: 'Tiền lương', child: Text('Tiền lương')),
              DropdownMenuItem(value: 'Khác', child: Text('Khác')),
            ],
            onChanged: (val) => setState(() => _category = val!),
            decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tiền', 
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder()
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Ghi chú', 
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder()
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: accounts.isEmpty ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF)),
              child: const Text('Lưu', style: TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}