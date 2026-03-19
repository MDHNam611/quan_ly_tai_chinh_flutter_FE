import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../state/account_cubit.dart';
import '../../data/models/account_model.dart';
import '../../../../injection_container.dart' as di; // Import GetIt
import '../../../transactions/presentation/state/transaction_cubit.dart'; // Import Cubit giao dịch
import '../../../transactions/presentation/pages/transaction_page.dart'; // Import Form
import '/features/accounts/presentation/widgets/account_forms.dart';


class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Hiển thị Menu 6 chức năng khi nhấn vào 1 tài khoản
  void _showAccountOptions(BuildContext context, AccountModel account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Tùy chọn: ${account.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context, 
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (ctx) => BlocProvider.value(
                      value: context.read<AccountCubit>(),
                      child: AccountActionForm(account: account), // Truyền account vào là Chỉnh sửa
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                title: const Text('Điều chỉnh số dư'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    builder: (ctx) => AdjustBalanceForm(account: account),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.purple),
                title: const Text('Xem giao dịch'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Yêu cầu 5: Mở trang Giao dịch và filter. Sẽ làm ở tính năng Giao dịch.
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.green),
                title: const Text('Nạp tiền (Thu nhập)'),
                onTap: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    builder: (ctx) => BlocProvider.value(
                      value: di.sl<TransactionCubit>(),
                      child: AddTransactionForm(initialAccountId: account.id, initialType: 'income', initialCategory: 'Tiền lương'),
                    ),
                  );
                  if (context.mounted) context.read<AccountCubit>().loadAccounts(); // Update số dư
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                title: const Text('Rút tiền (Chi phí)'),
                onTap: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    builder: (ctx) => BlocProvider.value(
                      value: di.sl<TransactionCubit>(),
                      child: AddTransactionForm(initialAccountId: account.id, initialType: 'expense'),
                    ),
                  );
                  if (context.mounted) context.read<AccountCubit>().loadAccounts(); // Update số dư
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.teal),
                title: const Text('Chuyển khoản'),
                onTap: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    builder: (ctx) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: di.sl<TransactionCubit>()),
                        BlocProvider.value(value: context.read<AccountCubit>()), // Chuyền AccountCubit để lấy DS ví đích
                      ],
                      child: TransferAccountForm(sourceAccount: account),
                    ),
                  );
                  if (context.mounted) context.read<AccountCubit>().loadAccounts(); // Update số dư 2 ví
                },
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              // MỞ FORM THÊM MỚI TÀI KHOẢN
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => BlocProvider.value(
                  value: context.read<AccountCubit>(),
                  child: const AccountActionForm(account: null), // account = null là Thêm mới
                ),
              );
            },
          )
        ],
      ),
      body: BlocConsumer<AccountCubit, AccountState>(
        listener: (context, state) {
          if (state is AccountError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AccountLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AccountLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.accounts.length,
              itemBuilder: (context, index) {
                final acc = state.accounts[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                    ),
                    title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: acc.description != null ? Text(acc.description!) : null,
                    trailing: Text(
                      currencyFormatter.format(acc.balance),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    onTap: () => _showAccountOptions(context, acc),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Chưa có dữ liệu'));
        },
      ),
    );
  }
}