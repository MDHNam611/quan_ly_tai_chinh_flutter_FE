import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/account_model.dart';
import 'package:do_an_quan_ly_tai_chinh/core/helpers/database_helper.dart';
import 'package:sqflite/sqflite.dart';

abstract class AccountState {}
class AccountInitial extends AccountState {}
class AccountLoading extends AccountState {}
class AccountLoaded extends AccountState {
  final List<AccountModel> accounts;
  final double totalBalance;
  AccountLoaded(this.accounts, this.totalBalance);
}
class AccountError extends AccountState {
  final String message;
  AccountError(this.message);
}

class AccountCubit extends Cubit<AccountState> {
  final DatabaseHelper dbHelper;

  AccountCubit({required this.dbHelper}) : super(AccountInitial());

  Future<void> loadAccounts() async {
    try {
      emit(AccountLoading());
      final db = await dbHelper.database;
      final maps = await db.query('accounts');
      
      final accounts = maps.map((e) => AccountModel.fromMap(e)).toList();
      
      // Tính tổng số dư của tất cả tài khoản
      final totalBalance = accounts.fold(0.0, (sum, item) => sum + item.balance);
      
      emit(AccountLoaded(accounts, totalBalance));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> addAccount(String name, String? description, String? icon) async {
    try {
      final db = await dbHelper.database;
      
      // 1. Kiểm tra giới hạn 5 tài khoản
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM accounts')) ?? 0;
      if (count >= 5) {
        emit(AccountError('Bạn chỉ được tạo tối đa 5 tài khoản.'));
        await loadAccounts(); // Load lại state cũ để mất thông báo lỗi loading
        return;
      }

      // 2. Tạo tài khoản mới
      final newAccount = AccountModel(
        id: const Uuid().v4(),
        name: name,
        balance: 0.0,
        description: description,
        icon: icon ?? 'wallet',
      );

      await db.insert('accounts', newAccount.toMap());
      await loadAccounts();
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
// Cập nhật thông tin tài khoản (Yêu cầu 3)
  Future<void> updateAccount(AccountModel account) async {
    try {
      emit(AccountLoading());
      final db = await dbHelper.database;
      await db.update(
        'accounts',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );
      await loadAccounts();
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  // Điều chỉnh số dư ngầm (Yêu cầu 4)
  Future<void> adjustBalance(String accountId, double newBalance) async {
    try {
      emit(AccountLoading());
      final db = await dbHelper.database;
      
      // Cập nhật số dư trực tiếp không thông qua giao dịch
      await db.update(
        'accounts',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [accountId],
      );
      
      // Tùy chọn: Nếu muốn ghi log ngầm thì insert 1 dòng vào bảng transactions ở đây
      // với thuộc tính isHidden = 1 (cần sửa DB để thêm trường này sau nếu cần).
      
      await loadAccounts();
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
  // Các hàm Update (Chỉnh sửa), Delete sẽ được bổ sung ở bước sau
}