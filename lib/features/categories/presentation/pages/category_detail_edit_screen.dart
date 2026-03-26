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

  // ĐÃ SỬA: Danh sách các tên màu tương thích với CategoryHelper.getColor()
  final List<String> _availableColors = [
    'red', 'blue', 'green', 'orange', 'purple', 
    'teal', 'pink', 'indigo', 'amber', 'cyan', 'brown', 'grey'
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8, // Chiếm 80% màn hình để dễ cuộn
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tùy chỉnh biểu tượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      
                      // CHỌN MÀU SẮC
                      const Text('Chọn màu sắc:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black54)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12, runSpacing: 12,
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
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // CHỌN BIỂU TƯỢNG (DÙNG EXPANSION TILE PHÂN NHÓM)
                      const Text('Chọn biểu tượng:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black54)),
                      const SizedBox(height: 12),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: CategoryHelper.categorizedIcons.keys.length,
                          itemBuilder: (context, catIndex) {
                            final categoryName = CategoryHelper.categorizedIcons.keys.elementAt(catIndex);
                            final iconsMap = CategoryHelper.categorizedIcons[categoryName]!;

                            // Kiểm tra xem icon hiện tại có nằm trong nhóm này không để tự động mở
                            final bool hasSelectedIcon = iconsMap.containsKey(_selectedIcon);

                            return ExpansionTile(
                              title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                              leading: const Icon(Icons.label_important_outline, color: Colors.blue),
                              initiallyExpanded: hasSelectedIcon, 
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                    itemCount: iconsMap.length,
                                    itemBuilder: (context, iconIndex) {
                                      final iconKey = iconsMap.keys.elementAt(iconIndex);
                                      final isSelected = _selectedIcon == iconKey;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() => _selectedIcon = iconKey);
                                          setState(() => _selectedIcon = iconKey);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected ? CategoryHelper.getColor(_selectedColor).withOpacity(0.2) : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isSelected ? CategoryHelper.getColor(_selectedColor) : Colors.grey.shade300, width: 2),
                                          ),
                                          child: Icon(iconsMap[iconKey], color: isSelected ? CategoryHelper.getColor(_selectedColor) : Colors.grey, size: 30),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                      ),
                      
                      // NÚT XONG
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CategoryHelper.getColor(_selectedColor), 
                            padding: const EdgeInsets.symmetric(vertical: 14)
                          ),
                          child: const Text('Xong', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
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