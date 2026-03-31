import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ĐÃ THÊM: Thư viện quản lý input formatters
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/models/transaction_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/data/models/account_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/data/models/category_model.dart';

import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/widgets/transaction_search_modal.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/widgets/transaction_action_modal.dart';
import 'package:do_an_quan_ly_tai_chinh/features/dashboard/presentation/widgets/period_selection_modal.dart';
import 'package:do_an_quan_ly_tai_chinh/core/widgets/custom_app_bar.dart';

class TransactionPage extends StatefulWidget {
  final TransactionFilter? initialFilter;

  const TransactionPage({super.key, this.initialFilter});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  PeriodType _currentPeriodType = PeriodType.month;
  String _periodTitle = 'THÁNG ${DateTime.now().month} ${DateTime.now().year}';
  DateTime? _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  late TransactionFilter _currentFilter;

  bool _isMultiSelectMode = false;
  final Set<TransactionModel> _selectedTransactions = {}; 

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? TransactionFilter();
  }

  void _shiftPeriod(int offset) {
    if (_startDate == null || _endDate == null) return;
    if (_currentPeriodType == PeriodType.all || _currentPeriodType == PeriodType.custom) return;

    setState(() {
      if (_currentPeriodType == PeriodType.month) {
        _startDate = DateTime(_startDate!.year, _startDate!.month + offset, 1);
        _endDate = DateTime(_startDate!.year, _startDate!.month + 1, 0, 23, 59, 59);
        _periodTitle = 'THÁNG ${_startDate!.month} ${_startDate!.year}';
      } 
      else if (_currentPeriodType == PeriodType.year) {
        _startDate = DateTime(_startDate!.year + offset, 1, 1);
        _endDate = DateTime(_startDate!.year + 1, 12, 31, 23, 59, 59);
        _periodTitle = 'NĂM ${_startDate!.year}';
      } 
      else if (_currentPeriodType == PeriodType.week) {
        _startDate = _startDate!.add(Duration(days: 7 * offset));
        _endDate = _endDate!.add(Duration(days: 7 * offset));
        _periodTitle = '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}';
      } 
      else if (_currentPeriodType == PeriodType.today || _currentPeriodType == PeriodType.specificDay) {
        _startDate = _startDate!.add(Duration(days: offset));
        _endDate = _endDate!.add(Duration(days: offset));
        _periodTitle = '${_startDate!.day} THÁNG ${_startDate!.month}';
      }
    });
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTransactions) {
    return allTransactions.where((tx) {
      final txDate = DateTime.parse(tx.date);
      if (_startDate != null && _endDate != null) {
        if (txDate.isBefore(_startDate!) || txDate.isAfter(_endDate!)) return false;
      }
      if (_currentFilter.type != null && tx.type != _currentFilter.type) return false;
      if (_currentFilter.accountIds.isNotEmpty && !_currentFilter.accountIds.contains(tx.accountId)) return false;
      if (_currentFilter.categories.isNotEmpty && !_currentFilter.categories.contains(tx.category)) return false;
      if (_currentFilter.note.isNotEmpty) {
        if (!tx.note.toLowerCase().contains(_currentFilter.note.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  void _toggleSelection(TransactionModel tx) {
    setState(() {
      if (_selectedTransactions.contains(tx)) {
        _selectedTransactions.remove(tx);
        if (_selectedTransactions.isEmpty) _isMultiSelectMode = false;
      } else {
        _selectedTransactions.add(tx);
        _isMultiSelectMode = true; 
      }
    });
  }

  void _toggleSelectAll() {
    final txState = context.read<TransactionCubit>().state;
    if (txState is TransactionLoaded) {
      final currentVisibleTxs = _getFilteredTransactions(txState.transactions);
      
      setState(() {
        if (_selectedTransactions.length == currentVisibleTxs.length) {
          _selectedTransactions.clear();
          _isMultiSelectMode = false;
        } else {
          _selectedTransactions.clear();
          _selectedTransactions.addAll(currentVisibleTxs);
        }
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTransactions.clear();
    });
  }

  void _showBulkDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa ${_selectedTransactions.length} giao dịch?', style: const TextStyle(color: Colors.red)),
        content: const Text('Số tiền của các giao dịch này sẽ được hoàn lại vào ví tương ứng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); 
              await context.read<TransactionCubit>().deleteMultipleTransactionsSecure(_selectedTransactions.toList());
              if (context.mounted) {
                context.read<AccountCubit>().loadAccounts();
                _clearSelection();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành công')));
              }
            },
            child: const Text('Xóa tất cả', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBulkDateModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ngày', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null && context.mounted) {
                  await context.read<TransactionCubit>().updateMultipleTransactionsDate(_selectedTransactions.toList(), picked);
                  _clearSelection();
                }
              },
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.calendar_month, color: Colors.black54), SizedBox(height: 4), Text('Chọn ngày', style: TextStyle(fontWeight: FontWeight.w500))])),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: InkWell(onTap: () async {
                  Navigator.pop(ctx);
                  final yesterday = DateTime.now().subtract(const Duration(days: 1));
                  await context.read<TransactionCubit>().updateMultipleTransactionsDate(_selectedTransactions.toList(), yesterday);
                  _clearSelection();
                }, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.nightlight_round, color: Colors.black54), SizedBox(height: 4), Text('Hôm qua', style: TextStyle(fontWeight: FontWeight.w500))])))),
                const SizedBox(width: 8),
                Expanded(child: InkWell(onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<TransactionCubit>().updateMultipleTransactionsDate(_selectedTransactions.toList(), DateTime.now());
                  _clearSelection();
                }, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.wb_sunny, color: Colors.black), SizedBox(height: 4), Text('Hôm nay', style: TextStyle(fontWeight: FontWeight.w500))])))),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      )
    );
  }

  void _showBulkAccountModal() {
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
              const Text('Chuyển sang tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...accountState.accounts.map((acc) => ListTile(
                leading: Icon(CategoryHelper.getIcon(acc.icon ?? 'wallet'), color: Colors.teal),
                title: Text(acc.name),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<TransactionCubit>().updateMultipleTransactionsAccount(_selectedTransactions.toList(), acc.id);
                  if (context.mounted) {
                    context.read<AccountCubit>().loadAccounts(); 
                    _clearSelection();
                  }
                },
              )),
            ],
          ),
        );
      }
    );
  }

  void _showBulkCategoryModal() {
    final types = _selectedTransactions.map((t) => t.type).toSet();
    if (types.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chỉ chọn các giao dịch CÙNG LOẠI (Thu hoặc Chi) để đổi danh mục'), backgroundColor: Colors.orange));
      return;
    }

    final targetType = types.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final categoryState = context.read<CategoryCubit>().state;
        if (categoryState is! CategoryLoaded) return const SizedBox();
        final categories = targetType == 'expense' ? categoryState.expenseCategories : categoryState.incomeCategories;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(targetType == 'expense' ? 'Chọn Danh mục Chi phí mới' : 'Chọn Danh mục Thu nhập mới', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 24, childAspectRatio: 0.75),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await context.read<TransactionCubit>().updateMultipleTransactionsCategory(_selectedTransactions.toList(), cat.name);
                        _clearSelection();
                      },
                      child: Column(
                        children: [
                          CircleAvatar(radius: 28, backgroundColor: CategoryHelper.getColor(cat.color).withOpacity(0.15), child: Icon(CategoryHelper.getIcon(cat.icon), color: CategoryHelper.getColor(cat.color), size: 28)),
                          const SizedBox(height: 8),
                          Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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

  String _getAccountName(String accountId) {
    final accountState = context.read<AccountCubit>().state;
    if (accountState is AccountLoaded) {
      final acc = accountState.accounts.firstWhere((a) => a.id == accountId, orElse: () => AccountModel(id: '', name: 'Ví đã xóa', balance: 0, icon: 'wallet'));
      return acc.name;
    }
    return 'Không rõ';
  }

  IconData _getAccountIcon(String accountId) {
    final accountState = context.read<AccountCubit>().state;
    if (accountState is AccountLoaded) {
      final acc = accountState.accounts.firstWhere((a) => a.id == accountId, orElse: () => AccountModel(id: '', name: '', balance: 0, icon: 'wallet'));
      return CategoryHelper.getIcon(acc.icon ?? 'wallet');
    }
    return Icons.account_balance_wallet_outlined;
  }

  CategoryModel? _getCategoryInfo(String categoryName) {
    final categoryState = context.read<CategoryCubit>().state;
    if (categoryState is CategoryLoaded) {
      try { return categoryState.expenseCategories.firstWhere((c) => c.name == categoryName); } catch (_) {}
      try { return categoryState.incomeCategories.firstWhere((c) => c.name == categoryName); } catch (_) {}
    }
    return null;
  }

  double _calculateDailyTotal(List<TransactionModel> transactions, DateTime date) {
    double total = 0;
    for (var tx in transactions) {
      final txDate = DateTime.parse(tx.date);
      if (txDate.year == date.year && txDate.month == date.month && txDate.day == date.day) {
        if (tx.type == 'expense') total -= tx.amount;
        if (tx.type == 'income') total += tx.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isArrowDisabled = _currentPeriodType == PeriodType.all || _currentPeriodType == PeriodType.custom;

    final Widget searchButton = IconButton(
      icon: Icon(Icons.search, color: _currentFilter.isEmpty ? Colors.black87 : Colors.blue),
      onPressed: () async {
        final result = await showDialog<TransactionFilter>(
          context: context,
          builder: (ctx) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AccountCubit>()),
              BlocProvider.value(value: context.read<CategoryCubit>()),
            ],
            child: TransactionSearchModal(initialFilter: _currentFilter),
          ),
        );
        if (result != null) setState(() => _currentFilter = result);
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isMultiSelectMode 
        ? AppBar(
            backgroundColor: Colors.blue.shade50,
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: _clearSelection),
            title: Text('${_selectedTransactions.length} đã chọn', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              IconButton(icon: const Icon(Icons.checklist, color: Colors.blue), onPressed: _toggleSelectAll),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _showBulkDeleteConfirm),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onSelected: (value) {
                  if (value == 'date') _showBulkDateModal();
                  if (value == 'account') _showBulkAccountModal();
                  if (value == 'category') _showBulkCategoryModal();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'date', child: Text('Thay đổi ngày')),
                  const PopupMenuItem(value: 'account', child: Text('Thay đổi tài khoản')),
                  const PopupMenuItem(value: 'category', child: Text('Thay đổi danh mục')),
                ],
              )
            ],
          )
        : (Navigator.canPop(context) 
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
                title: Column(
                  children: [
                    const Text('Tất cả các tài khoản', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    BlocBuilder<AccountCubit, AccountState>(
                      builder: (context, state) {
                        double totalBalance = 0;
                        if (state is AccountLoaded) {
                          for (var acc in state.accounts) totalBalance += acc.balance;
                        }
                        return Text(currencyFormatter.format(totalBalance), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18));
                      },
                    ),
                  ],
                ),
                centerTitle: true,
                actions: [searchButton],
              )
            : CustomAppBar(
                backgroundColor: Colors.white,
                actions: [searchButton],
              )
          ),

      body: Column(
        children: [
          if (!_isMultiSelectMode) ...[
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                int transactionCount = 0;
                if (state is TransactionLoaded) {
                  transactionCount = _getFilteredTransactions(state.transactions).length;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: Icon(Icons.keyboard_double_arrow_left, color: isArrowDisabled ? Colors.grey.shade300 : Colors.grey), onPressed: isArrowDisabled ? null : () => _shiftPeriod(-1)),
                      InkWell(
                        onTap: () async {
                          final result = await showModalBottomSheet<PeriodFilter>(
                            context: context,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (ctx) => PeriodSelectionModal(currentType: _currentPeriodType),
                          );

                          if (result != null) {
                            setState(() {
                              _currentPeriodType = result.type;
                              _periodTitle = result.title.toUpperCase();
                              _startDate = result.startDate;
                              _endDate = result.endDate;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Text('$transactionCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              const SizedBox(width: 8),
                              Text(_periodTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                      IconButton(icon: Icon(Icons.keyboard_double_arrow_right, color: isArrowDisabled ? Colors.grey.shade300 : Colors.grey), onPressed: isArrowDisabled ? null : () => _shiftPeriod(1)),
                    ],
                  ),
                );
              }
            ),
            const Divider(thickness: 1, height: 1),
          ],

          Expanded(
            child: BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) return const Center(child: CircularProgressIndicator());
                if (state is TransactionLoaded) {
                  
                  List<TransactionModel> filteredList = _getFilteredTransactions(state.transactions);

                  if (filteredList.isEmpty) return const Center(child: Text('Không tìm thấy giao dịch nào', style: TextStyle(color: Colors.grey)));

                  return GroupedListView<TransactionModel, DateTime>(
                    elements: filteredList,
                    groupBy: (tx) {
                      final date = DateTime.parse(tx.date);
                      return DateTime(date.year, date.month, date.day);
                    },
                    order: GroupedListOrder.DESC,
                    itemComparator: (item1, item2) => DateTime.parse(item1.date).compareTo(DateTime.parse(item2.date)),
                    useStickyGroupSeparators: false,
                    groupSeparatorBuilder: (DateTime date) {
                      final now = DateTime.now();
                      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                      final isYesterday = date.year == now.year && date.month == now.month && date.day == now.day - 1;
                      
                      String dayText = isToday ? 'HÔM NAY' : (isYesterday ? 'HÔM QUA' : DateFormat('EEEE', 'vi_VN').format(date).toUpperCase());
                      double dailyTotal = _calculateDailyTotal(filteredList, date);

                      return Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('${date.day}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Color(0xFF3F51B5))),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dayText, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text('THÁNG ${date.month} ${date.year}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              currencyFormatter.format(dailyTotal.abs()),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dailyTotal < 0 ? Colors.pink.shade400 : Colors.teal),
                            ),
                          ],
                        ),
                      );
                    },
                    itemBuilder: (context, tx) {
                      final isExpense = tx.type == 'expense';
                      final catInfo = _getCategoryInfo(tx.category);
                      final iconData = catInfo != null ? CategoryHelper.getIcon(catInfo.icon) : (isExpense ? Icons.restaurant : Icons.payments);
                      final bgColor = catInfo != null ? CategoryHelper.getColor(catInfo.color) : (isExpense ? const Color(0xFF3F51B5) : Colors.teal);
                      final accountIcon = _getAccountIcon(tx.accountId);
                      
                      final isSelected = _selectedTransactions.contains(tx);

                      return InkWell(
                        onLongPress: () => _toggleSelection(tx),
                        onTap: () {
                          if (_isMultiSelectMode) {
                            _toggleSelection(tx);
                          } else {
                            TransactionActionModal.showOptions(context, tx);
                          }
                        },
                        child: Container(
                          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isSelected ? Colors.blue : bgColor,
                                child: isSelected 
                                    ? const Icon(Icons.check, color: Colors.white) 
                                    : Icon(iconData, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(accountIcon, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(_getAccountName(tx.accountId), style: const TextStyle(fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    if (tx.note.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(tx.note, style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ]
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormatter.format(tx.amount),
                                style: TextStyle(color: isExpense ? Colors.pink.shade400 : Colors.teal, fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode ? null : FloatingActionButton(
        backgroundColor: const Color(0xFFD6C4FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<TransactionCubit>()),
                BlocProvider.value(value: context.read<AccountCubit>()),
                BlocProvider.value(value: context.read<CategoryCubit>()),
              ],
              child: const AddTransactionForm(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// =========================================================
// FORM THÊM GIAO DỊCH 
// =========================================================
class AddTransactionForm extends StatefulWidget {
  final String? initialAccountId;
  final String? initialType;
  final String? initialCategory;
  final bool isFixed; // ĐÃ THÊM: Biến khóa Nạp/Rút

  const AddTransactionForm({super.key, this.initialAccountId, this.initialType, this.initialCategory, this.isFixed = false});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _type;
  String? _category;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'expense';
    _category = widget.initialCategory;
    _accountId = widget.initialAccountId;
  }

  void _save() {
    if (_amountController.text.isEmpty || _accountId == null || _category == null) return;

    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount <= 0) return;

    final newTx = TransactionModel(
      accountId: _accountId!,
      category: _category!,
      type: _type,
      amount: amount,
      note: _noteController.text,
      date: DateTime.now().toIso8601String(),
      offlineId: const Uuid().v4(),
    );

    context.read<TransactionCubit>().addTransaction(newTx);
    context.read<AccountCubit>().loadAccounts();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accountState = context.read<AccountCubit>().state;
    List<AccountModel> accounts = accountState is AccountLoaded ? accountState.accounts : [];
    if (accounts.isNotEmpty && (_accountId == null || !accounts.any((a) => a.id == _accountId))) {
      _accountId = accounts.first.id;
    }

    final categoryState = context.read<CategoryCubit>().state;
    List<String> categories = [];
    if (categoryState is CategoryLoaded) {
      categories = _type == 'expense' 
          ? categoryState.expenseCategories.map((c) => c.name).toList()
          : categoryState.incomeCategories.map((c) => c.name).toList();
    }
    if (categories.isNotEmpty && (_category == null || !categories.contains(_category))) {
      _category = categories.first;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thêm giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // ĐÃ SỬA: LOGIC ẨN/HIỆN NÚT THU CHI
          if (widget.isFixed)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _type == 'income' ? 'Loại: Thu nhập (Nạp tiền)' : 'Loại: Chi phí (Rút tiền)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _type == 'income' ? Colors.green : Colors.red,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(child: RadioListTile<String>(title: const Text('Chi'), value: 'expense', groupValue: _type, onChanged: (val) => setState(() { _type = val!; _category = null; }))),
                Expanded(child: RadioListTile<String>(title: const Text('Thu'), value: 'income', groupValue: _type, onChanged: (val) => setState(() { _type = val!; _category = null; }))),
              ],
            ),
            
          if (accounts.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _accountId,
              items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
              onChanged: (val) => setState(() => _accountId = val),
              decoration: const InputDecoration(labelText: 'Tài khoản', border: OutlineInputBorder()),
            )
          else const Text('Vui lòng tạo tài khoản trước', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          if (categories.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _category,
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _category = val),
              decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
            )
          else const Text('Vui lòng tạo danh mục trước', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          
          // ĐÃ SỬA: CHẶN 13 KÝ TỰ SỐ TIỀN Ở ĐÂY
          TextField(
            controller: _amountController, 
            keyboardType: TextInputType.number, 
            autofocus: true, 
            decoration: const InputDecoration(labelText: 'Số tiền', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
          
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.note), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: accounts.isEmpty || categories.isEmpty ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF)), child: const Text('Lưu', style: TextStyle(color: Colors.black)))),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}