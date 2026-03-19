import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/data/models/category_model.dart';

// --- MÀN HÌNH QUẢN LÝ (CÓ 2 TAB THU/CHI) ---
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Chỉnh sửa danh mục', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_downward, size: 16), SizedBox(width: 4), Text('Chi phí')])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_upward, size: 16), SizedBox(width: 4), Text('Thu nhập')])),
            ],
          ),
        ),
        body: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoryLoaded) {
              return TabBarView(
                children: [
                  _buildCategoryGrid(context, state.expenseCategories, 'expense'),
                  _buildCategoryGrid(context, state.incomeCategories, 'income'),
                ],
              );
            }
            return const Center(child: Text('Lỗi tải dữ liệu'));
          },
        ),
      ),
    );
  }

  // LƯỚI HIỂN THỊ DANH MỤC TRONG TAB
  Widget _buildCategoryGrid(BuildContext context, List<CategoryModel> categories, String type) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 cột giống thiết kế
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.75, // Chỉnh tỷ lệ để chữ không bị lẹm
      ),
      // Cấp thêm 1 ô cho nút "+" nếu chưa đủ 9 danh mục
      itemCount: categories.length < 9 ? categories.length + 1 : categories.length,
      itemBuilder: (context, index) {
        // Nút Thêm mới
        if (index == categories.length) {
          return GestureDetector(
            onTap: () => _showCategoryForm(context, null, type),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade100,
                  child: const Icon(Icons.add, color: Colors.grey, size: 28),
                ),
                const SizedBox(height: 8),
                const Text('Thêm', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        // Các danh mục hiện có
        final cat = categories[index];
        return GestureDetector(
          onTap: () => _showCategoryForm(context, cat, type),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: CategoryHelper.getColor(cat.color).withOpacity(0.15),
                child: Icon(CategoryHelper.getIcon(cat.icon), color: CategoryHelper.getColor(cat.color), size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                cat.name,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // Gọi form thêm/sửa danh mục từ dưới lên
  void _showCategoryForm(BuildContext context, CategoryModel? category, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => BlocProvider.value(
        value: context.read<CategoryCubit>(), // Chuyền Cubit vào form
        child: CategoryActionForm(category: category, type: type),
      ),
    );
  }
}

// --- FORM THÊM / SỬA / XÓA DANH MỤC ---
class CategoryActionForm extends StatefulWidget {
  final CategoryModel? category;
  final String type;

  const CategoryActionForm({super.key, this.category, required this.type});

  @override
  State<CategoryActionForm> createState() => _CategoryActionFormState();
}

class _CategoryActionFormState extends State<CategoryActionForm> {
  late TextEditingController _nameController;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'more_horiz';
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return; // Chặn lưu danh mục rỗng

    if (widget.category == null) {
      context.read<CategoryCubit>().addCategory(name, widget.type, _selectedIcon);
    } else {
      final updatedCat = CategoryModel(
        id: widget.category!.id,
        name: name,
        type: widget.category!.type,
        icon: _selectedIcon,
        color: widget.category!.color, // Giữ nguyên màu hiện tại
      );
      // Truyền thêm oldName để Cập nhật tên giao dịch cũ
      context.read<CategoryCubit>().updateCategory(updatedCat, widget.category!.name);
    }
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cảnh báo xóa', style: TextStyle(color: Colors.red)),
        content: const Text(
            'Việc xóa danh mục này sẽ đồng thời chuyển TẤT CẢ các giao dịch liên quan sang danh mục "Khác".\n\nBạn có chắc chắn muốn xóa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryCubit>().deleteCategory(widget.category!.id);
              Navigator.pop(ctx); // Đóng Alert
              Navigator.pop(context); // Đóng Form BottomSheet
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.category == null ? 'Thêm danh mục' : 'Chỉnh sửa danh mục', 
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            autofocus: widget.category == null,
            decoration: const InputDecoration(labelText: 'Tên danh mục', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          
          const Text('Chọn Biểu tượng:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          
          // Bảng chọn Icon trực quan
          SizedBox(
            height: 150,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: CategoryHelper.icons.length,
              itemBuilder: (context, index) {
                final iconKey = CategoryHelper.icons.keys.elementAt(index);
                final isSelected = _selectedIcon == iconKey;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconKey),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD6C4FF) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? Colors.purple : Colors.grey.shade300),
                    ),
                    child: Icon(CategoryHelper.getIcon(iconKey), color: isSelected ? Colors.purple : Colors.grey),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              if (widget.category != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Xóa'),
                  ),
                ),
              if (widget.category != null) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6C4FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}