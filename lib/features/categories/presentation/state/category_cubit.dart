import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category_model.dart';
import '../../../../core/helpers/database_helper.dart';
import 'package:sqflite/sqflite.dart';

abstract class CategoryState {}
class CategoryInitial extends CategoryState {}
class CategoryLoading extends CategoryState {}
class CategoryLoaded extends CategoryState {
  final List<CategoryModel> incomeCategories;
  final List<CategoryModel> expenseCategories;
  CategoryLoaded(this.incomeCategories, this.expenseCategories);
}
class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

class CategoryCubit extends Cubit<CategoryState> {
  final DatabaseHelper dbHelper;

  CategoryCubit({required this.dbHelper}) : super(CategoryInitial());

  Future<void> loadCategories() async {
    try {
      emit(CategoryLoading());
      final db = await dbHelper.database;
      final maps = await db.query('categories');
      
      final allCategories = maps.map((e) => CategoryModel.fromMap(e)).toList();
      
      final incomeCategories = allCategories.where((c) => c.type == 'income').toList();
      final expenseCategories = allCategories.where((c) => c.type == 'expense').toList();
      
      emit(CategoryLoaded(incomeCategories, expenseCategories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  // Yêu cầu 2: Tạo danh mục mới kèm check giới hạn 9
  Future<void> addCategory(String name, String type, String icon) async {
    try {
      final db = await dbHelper.database;
      
      // Kiểm tra giới hạn 9 danh mục cho loại (Thu/Chi) tương ứng
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categories WHERE type = ?', [type])
      ) ?? 0;
      
      if (count >= 9) {
        emit(CategoryError('Chỉ được tạo tối đa 9 danh mục cho mỗi loại.'));
        await loadCategories(); // Load lại để ẩn loading
        return;
      }

      final newCat = CategoryModel(
        id: const Uuid().v4(),
        name: name,
        type: type,
        icon: icon,
        color: '#D6C4FF', // Màu mặc định cho danh mục mới
      );

      await db.insert('categories', newCat.toMap());
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  // Yêu cầu 3: Chỉnh sửa tên, icon và đồng bộ tên giao dịch cũ
  Future<void> updateCategory(CategoryModel category, String oldName) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // 1. Cập nhật bảng Danh mục
        await txn.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
        
        // 2. Nếu có đổi tên, phải cập nhật luôn tên danh mục trong lịch sử giao dịch
        if (category.name != oldName) {
          await txn.rawUpdate('UPDATE transactions SET category = ? WHERE category = ?', [category.name, oldName]);
        }
      });
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
  // Yêu cầu 1: Xóa danh mục + Xóa giao dịch + HOÀN TIỀN VÀO VÍ
  Future<void> deleteCategory(String id) async {
    try {
      final db = await dbHelper.database;
      
      // 1. Lấy thông tin danh mục chuẩn bị xóa
      final catToDelete = await db.query('categories', where: 'id = ?', whereArgs: [id]);
      if (catToDelete.isEmpty) return;
      
      final type = catToDelete.first['type'] as String;
      final catName = catToDelete.first['name'] as String;

      // Chặn xóa nếu là danh mục cuối cùng của loại đó (Thu/Chi)
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories WHERE type = ?', [type])) ?? 0;
      if (count <= 1) {
        emit(CategoryError('Không thể xóa danh mục cuối cùng.'));
        await loadCategories();
        return;
      }

      // 2. Thực thi Transaction an toàn (Hoàn tiền -> Xóa Giao dịch -> Xóa Danh mục)
      await db.transaction((txn) async {
        // Lấy tất cả giao dịch thuộc danh mục này
        final txsToDelete = await txn.query('transactions', where: 'category = ?', whereArgs: [catName]);
        
        // Hoàn lại tiền cho từng ví
        for (var tx in txsToDelete) {
          final amount = tx['amount'] as double;
          final accountId = tx['accountId'] as String;
          
          if (type == 'expense') {
            // Hoàn tiền cho Chi phí: Cộng lại vào ví
            await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [amount, accountId]);
          } else if (type == 'income') {
            // Hoàn tiền cho Thu nhập: Trừ đi khỏi ví
            await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, accountId]);
          }
        }
        
        // Xóa toàn bộ giao dịch mang tên danh mục này
        await txn.delete('transactions', where: 'category = ?', whereArgs: [catName]);
        
        // Cuối cùng, xóa danh mục
        await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
      });
      
      await loadCategories();
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}