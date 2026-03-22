import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/data/models/category_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';

class CategoryDetailEditScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailEditScreen({super.key, required this.category});

  @override
  State<CategoryDetailEditScreen> createState() => _CategoryDetailEditScreenState();
}

class _CategoryDetailEditScreenState extends State<CategoryDetailEditScreen> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;

  // DANH SÁCH MÀU VÀ ICON TẠO SẴN CHO UI (Khắc phục lỗi không tìm thấy iconMap/colorMap)
  final List<String> _availableIcons = [
    'restaurant', 'shopping_cart', 'local_gas_station', 'directions_bus',
    'home', 'build', 'health_and_safety', 'wifi', 'shopping_bag',
    'school', 'sports_esports', 'pets', 'card_giftcard', 'wallet',
    'money', 'savings', 'account_balance', 'category', 'more_horiz'
  ];

  final List<String> _availableColors = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5',
    '#2196F3', '#00BCD4', '#009688', '#4CAF50', '#8BC34A',
    '#FFC107', '#FF9800', '#FF5722', '#795548', '#9E9E9E', '#607D8B'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.icon;
    _selectedColor = widget.category.color;
  }

  void _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên danh mục không được để trống')));
      return;
    }

    final updatedCategory = CategoryModel(
      id: widget.category.id,
      name: newName,
      type: widget.category.type,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    await context.read<CategoryCubit>().updateCategory(updatedCategory, widget.category.name);
    
    if (context.mounted) {
      context.read<TransactionCubit>().loadTransactions();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật danh mục')));
    }
  }

  void _deleteCategory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa danh mục?', style: TextStyle(color: Colors.red)),
        content: const Text('Tất cả giao dịch thuộc danh mục này sẽ bị xóa và TIỀN SẼ ĐƯỢC HOÀN LẠI VÀO VÍ.\nBạn có chắc chắn muốn tiếp tục?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); 
              
              // ĐÃ SỬA: Xóa dấu ! thừa thãi ở widget.category.id
              await context.read<CategoryCubit>().deleteCategory(widget.category.id);
              
              if (context.mounted) {
                context.read<TransactionCubit>().loadTransactions();
                context.read<AccountCubit>().loadAccounts();
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục và hoàn tiền')));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIconColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chọn biểu tượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      // ĐÃ SỬA: Dùng list local _availableIcons
                      children: _availableIcons.map((iconName) {
                        final isSelected = _selectedIcon == iconName;
                        return InkWell(
                          onTap: () {
                            setModalState(() => _selectedIcon = iconName);
                            setState(() => _selectedIcon = iconName); 
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                            child: Icon(CategoryHelper.getIcon(iconName), color: isSelected ? Colors.blue : Colors.black54),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Chọn màu sắc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      // ĐÃ SỬA: Dùng list local _availableColors
                      children: _availableColors.map((colorName) {
                        final isSelected = _selectedColor == colorName;
                        final colorValue = CategoryHelper.getColor(colorName);
                        return InkWell(
                          onTap: () {
                            setModalState(() => _selectedColor = colorName);
                            setState(() => _selectedColor = colorName);
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: colorValue,
                            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text('Danh mục', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Lưu', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tên danh mục', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 24, color: Colors.black87, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _showIconColorPicker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CategoryHelper.getColor(_selectedColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(CategoryHelper.getIcon(_selectedIcon), color: Colors.white, size: 32),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),

            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa danh mục', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500)),
              contentPadding: EdgeInsets.zero,
              onTap: _deleteCategory, 
            ),
          ],
        ),
      ),
    );
  }
}