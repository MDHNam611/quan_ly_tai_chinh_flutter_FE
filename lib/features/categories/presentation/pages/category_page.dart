import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; 

import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/data/models/category_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/dashboard/presentation/widgets/period_selection_modal.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/models/transaction_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/pages/category_detail_edit_screen.dart';
// ĐÃ THÊM: Import các file cần thiết của trang Giao dịch
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/pages/transaction_page.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/widgets/transaction_search_modal.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  PeriodType _currentPeriodType = PeriodType.month;
  String _periodTitle = 'THÁNG ${DateTime.now().month} ${DateTime.now().year}';
  DateTime? _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  bool _isExpenseTab = true;
  bool _isEditMode = false;

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

  double _calculateCategoryTotal(List<TransactionModel> allTransactions, String categoryName, String type) {
    double total = 0;
    for (var tx in allTransactions) {
      if (tx.category == categoryName && tx.type == type) {
        final txDate = DateTime.parse(tx.date);
        if (_startDate != null && _endDate != null) {
          if (txDate.isAfter(_startDate!.subtract(const Duration(seconds: 1))) && 
              txDate.isBefore(_endDate!.add(const Duration(seconds: 1)))) {
            total += tx.amount;
          }
        } else {
          total += tx.amount; 
        }
      }
    }
    return total;
  }

  List<PieChartSectionData> _generateChartData(List<CategoryModel> categories, List<TransactionModel> transactions, String type) {
    List<PieChartSectionData> sections = [];
    
    for (var cat in categories) {
      final total = _calculateCategoryTotal(transactions, cat.name, type);
      if (total > 0) { 
        sections.add(PieChartSectionData(
          color: CategoryHelper.getColor(cat.color),
          value: total,
          title: '', 
          radius: 12, 
        ));
      }
    }

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(color: Colors.grey.shade200, value: 1, title: '', radius: 12));
    }

    return sections;
  }

  // ĐÃ THÊM: HÀM TẠO NÚT TRONG BOTTOM SHEET
  Widget _buildBottomSheetButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(icon, color: color, size: 28)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  // ĐÃ THÊM: HÀM HIỂN THỊ MENU KHI NHẤN GIỮ (YÊU CẦU 3)
  void _showCategoryActionMenu(CategoryModel category, String typeString) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.blue.shade700, // Giao diện xanh đen giống ảnh thiết kế
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Icon + Tên + Nút X
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        children: [
                          Icon(CategoryHelper.getIcon(category.icon), color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(category.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 12),
                          InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: Colors.white, size: 20))
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // 2 Nút Tùy chọn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomSheetButton(icon: Icons.edit, color: Colors.orange.shade300, label: 'Chỉnh sửa', onTap: () {
                      Navigator.pop(ctx);
                      // Tới trang chỉnh sửa danh mục
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailEditScreen(category: category)));
                    }),
                    _buildBottomSheetButton(icon: Icons.receipt_long, color: Colors.blue.shade300, label: 'Giao dịch', onTap: () {
                      Navigator.pop(ctx);
                      // Tạo bộ lọc chứa danh mục này và mở trang Giao Dịch
                      final filter = TransactionFilter(categories: [category.name], type: typeString);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPage(initialFilter: filter)));
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isArrowDisabled = _currentPeriodType == PeriodType.all || _currentPeriodType == PeriodType.custom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isEditMode 
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => setState(() => _isEditMode = false))
            : const Icon(Icons.account_circle_outlined, color: Colors.black54, size: 28),
        title: _isEditMode
            ? const Text('Chỉnh sửa danh mục', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18))
            : Column(
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
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black87), 
              onPressed: () => setState(() => _isEditMode = true),
            )
        ],
      ),
      body: Column(
        children: [
          // BỘ CHỌN KỲ
          Padding(
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_periodTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.keyboard_double_arrow_right, color: isArrowDisabled ? Colors.grey.shade300 : Colors.grey), onPressed: isArrowDisabled ? null : () => _shiftPeriod(1)),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1),

          // TAB CHUYỂN ĐỔI THU / CHI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpenseTab = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isExpenseTab ? Colors.pink.shade400 : Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))
                      ),
                      alignment: Alignment.center,
                      child: Text('Chi phí', style: TextStyle(color: _isExpenseTab ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  )
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpenseTab = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isExpenseTab ? Colors.teal : Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))
                      ),
                      alignment: Alignment.center,
                      child: Text('Thu nhập', style: TextStyle(color: !_isExpenseTab ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  )
                ),
              ],
            ),
          ),

          // NỘI DUNG CHÍNH 
          Expanded(
            child: BlocConsumer<CategoryCubit, CategoryState>(
              listener: (context, state) {
                if (state is CategoryError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                }
              },
              builder: (context, catState) {
                return BlocBuilder<TransactionCubit, TransactionState>(
                  builder: (context, txState) {
                    if (catState is CategoryLoading || txState is TransactionLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (catState is CategoryLoaded && txState is TransactionLoaded) {
                      final displayCategories = _isExpenseTab ? catState.expenseCategories : catState.incomeCategories;
                      final typeString = _isExpenseTab ? 'expense' : 'income';

                      double grandTotal = 0;
                      for (var cat in displayCategories) {
                        grandTotal += _calculateCategoryTotal(txState.transactions, cat.name, typeString);
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // BIỂU ĐỒ DONUT 
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 24),
                              width: 220,
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 2, 
                                      centerSpaceRadius: 90, 
                                      sections: _generateChartData(displayCategories, txState.transactions, typeString),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_isExpenseTab ? 'Chi phí' : 'Thu nhập', style: const TextStyle(color: Colors.black87, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormatter.format(grandTotal), 
                                        style: TextStyle(color: _isExpenseTab ? Colors.pink.shade400 : Colors.teal, fontWeight: FontWeight.bold, fontSize: 18)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // LƯỚI DANH MỤC
                            Wrap(
                              spacing: 24, 
                              runSpacing: 24,
                              alignment: WrapAlignment.center,
                              children: displayCategories.map((cat) {
                                final catTotal = _calculateCategoryTotal(txState.transactions, cat.name, typeString);

                                return InkWell(
                                  // ĐÃ SỬA: NHẤN GIỮ HIỆN MENU (Yêu cầu 3)
                                  onLongPress: () {
                                    if (!_isEditMode) _showCategoryActionMenu(cat, typeString);
                                  },
                                  // ĐÃ SỬA: NHẤN BÌNH THƯỜNG (Yêu cầu 2)
                                  onTap: () {
                                    if (_isEditMode) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailEditScreen(category: cat)));
                                    } else {
                                      // Hiện form thêm giao dịch gài sẵn Danh mục
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
                                          child: AddTransactionForm(
                                            initialType: typeString, 
                                            initialCategory: cat.name // Gài sẵn danh mục
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: SizedBox(
                                    width: 80, 
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: CategoryHelper.getColor(cat.color),
                                          child: Icon(CategoryHelper.getIcon(cat.icon), color: Colors.white, size: 28),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(cat.name, style: const TextStyle(fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(
                                          currencyFormatter.format(catTotal), 
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CategoryHelper.getColor(cat.color)),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList()
                              ..addAll(_isEditMode ? [
                                InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                      builder: (ctx) => BlocProvider.value(
                                        value: context.read<CategoryCubit>(),
                                        child: AddCategoryForm(type: typeString),
                                      ),
                                    );
                                  },
                                  child: const SizedBox(
                                    width: 80,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(radius: 28, backgroundColor: Colors.transparent, child: Icon(Icons.add_circle_outline, color: Colors.grey, size: 36)),
                                        SizedBox(height: 8),
                                        Text('Thêm', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                )
                              ] : []),
                            ),
                            const SizedBox(height: 40), 
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  }
                );
              }
            )
          )
        ],
      ),
    );
  }
}

// =========================================================
// FORM THÊM MỚI DANH MỤC
// =========================================================
class AddCategoryForm extends StatefulWidget {
  final String type; 

  const AddCategoryForm({super.key, required this.type});

  @override
  State<AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<AddCategoryForm> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'category';

  final List<String> _availableIcons = [
    'restaurant', 'shopping_cart', 'local_gas_station', 'directions_bus',
    'home', 'build', 'health_and_safety', 'wifi', 'shopping_bag',
    'school', 'sports_esports', 'pets', 'card_giftcard', 'wallet',
    'money', 'savings', 'account_balance', 'category', 'more_horiz'
  ];

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên danh mục')));
      return;
    }
    
    context.read<CategoryCubit>().addCategory(name, widget.type, _selectedIcon);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thêm danh mục ${widget.type == 'expense' ? 'Chi phí' : 'Thu nhập'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Tên danh mục', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          
          const Text('Chọn biểu tượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: _availableIcons.map((iconName) {
              final isSelected = _selectedIcon == iconName;
              return InkWell(
                onTap: () => setState(() => _selectedIcon = iconName),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                  child: Icon(CategoryHelper.getIcon(iconName), color: isSelected ? Colors.blue : Colors.black54),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Lưu', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}