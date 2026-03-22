import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';

// Class lưu trữ trạng thái của Bộ lọc
class TransactionFilter {
  String note;
  String? type; // 'income', 'expense', 'transfer', hoặc null (tất cả)
  List<String> accountIds;
  List<String> categories;

  TransactionFilter({
    this.note = '',
    this.type,
    this.accountIds = const [],
    this.categories = const [],
  });

  bool get isEmpty => note.isEmpty && type == null && accountIds.isEmpty && categories.isEmpty;
}

class TransactionSearchModal extends StatefulWidget {
  final TransactionFilter initialFilter;

  const TransactionSearchModal({super.key, required this.initialFilter});

  @override
  State<TransactionSearchModal> createState() => _TransactionSearchModalState();
}

class _TransactionSearchModalState extends State<TransactionSearchModal> {
  late TextEditingController _noteController;
  String? _selectedType;
  List<String> _selectedAccounts = [];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialFilter.note);
    _selectedType = widget.initialFilter.type;
    _selectedAccounts = List.from(widget.initialFilter.accountIds);
    _selectedCategories = List.from(widget.initialFilter.categories);
  }

  void _toggleAccount(String id) {
    setState(() {
      if (_selectedAccounts.contains(id)) {
        _selectedAccounts.remove(id);
      } else {
        _selectedAccounts.add(id);
      }
    });
  }

  void _toggleCategory(String name) {
    setState(() {
      if (_selectedCategories.contains(name)) {
        _selectedCategories.remove(name);
      } else {
        _selectedCategories.add(name);
      }
    });
  }

  void _applyFilter() {
    final filter = TransactionFilter(
      note: _noteController.text.trim(),
      type: _selectedType,
      accountIds: _selectedAccounts,
      categories: _selectedCategories,
    );
    Navigator.pop(context, filter); // Trả filter về cho trang trước
  }

  void _clearFilter() {
    setState(() {
      _noteController.clear();
      _selectedType = null;
      _selectedAccounts.clear();
      _selectedCategories.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountState = context.read<AccountCubit>().state;
    final categoryState = context.read<CategoryCubit>().state;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text('Tìm kiếm', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _clearFilter,
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _applyFilter,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Xong', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TÌM KIẾM GHI CHÚ
            const Text('Ghi chú', style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Ghi chú...',
                prefixIcon: const Icon(Icons.receipt_long, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 24),

            // 2. LOẠI GIAO DỊCH
            const Text('Loại giao dịch', style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeButton('Chi phí', 'expense', Icons.arrow_downward, Colors.pink),
                const SizedBox(width: 8),
                _buildTypeButton('Thu nhập', 'income', Icons.arrow_upward, Colors.teal),
                const SizedBox(width: 8),
                _buildTypeButton('Chuyển khoản', 'transfer', Icons.swap_horiz, Colors.grey),
              ],
            ),
            const SizedBox(height: 24),

            // 3. TÀI KHOẢN
            const Text('Tài khoản', style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (accountState is AccountLoaded)
              Wrap(
                spacing: 8, runSpacing: 8,
                children: accountState.accounts.map((acc) {
                  final isSelected = _selectedAccounts.contains(acc.id);
                  return FilterChip(
                    label: Text(acc.name),
                    selected: isSelected,
                    onSelected: (_) => _toggleAccount(acc.id),
                    avatar: Icon(CategoryHelper.getIcon(acc.icon ?? 'wallet'), size: 18, color: isSelected ? Colors.white : Colors.blue),
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // 4. CHI PHÍ (Chỉ hiện nếu không chọn Thu Nhập hoặc Chuyển khoản)
            if (_selectedType == null || _selectedType == 'expense') ...[
              const Text('Chi phí', style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (categoryState is CategoryLoaded)
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: categoryState.expenseCategories.map((cat) {
                    final isSelected = _selectedCategories.contains(cat.name);
                    final color = CategoryHelper.getColor(cat.color);
                    return FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(cat.name),
                      avatar: Icon(CategoryHelper.getIcon(cat.icon), size: 18, color: isSelected ? Colors.white : color),
                      selectedColor: color,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : color),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(side: BorderSide(color: color), borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
            ],

            // 5. THU NHẬP
            if (_selectedType == null || _selectedType == 'income') ...[
              const Text('Thu nhập', style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (categoryState is CategoryLoaded)
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: categoryState.incomeCategories.map((cat) {
                    final isSelected = _selectedCategories.contains(cat.name);
                    final color = CategoryHelper.getColor(cat.color);
                    return FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(cat.name),
                      avatar: Icon(CategoryHelper.getIcon(cat.icon), size: 18, color: isSelected ? Colors.white : color),
                      selectedColor: color,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : color),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(side: BorderSide(color: color), borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
            ],
            const SizedBox(height: 40), // Spacing for bottom
          ],
        ),
      ),
    );
  }

  // Widget tạo nút bấm Loại Giao Dịch
  Widget _buildTypeButton(String label, String value, IconData icon, Color color) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = isSelected ? null : value; // Bấm lại thì hủy chọn
            // Tự động clear danh mục nếu đổi loại giao dịch để tránh lỗi xung đột (Blind spot 1)
            _selectedCategories.clear(); 
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}