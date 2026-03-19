import 'package:get_it/get_it.dart';
import 'package:do_an_quan_ly_tai_chinh/core/helpers/database_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/datasources/local_datasource.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/repositories/transaction_repository_impl.dart';
// Đã sửa import trỏ về đúng thư mục domain
import 'package:do_an_quan_ly_tai_chinh/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/dashboard/presentation/state/dashboard_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // Data sources
  sl.registerLazySingleton<TransactionLocalDataSource>(() => TransactionLocalDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(sl()));

  // Cubits
  sl.registerFactory<TransactionCubit>(() => TransactionCubit(repository: sl()));

  // Cubits tài khoản
  sl.registerFactory<AccountCubit>(() => AccountCubit(dbHelper: sl()));

  // Cubit Dashboard
  sl.registerFactory<DashboardCubit>(() => DashboardCubit(dbHelper: sl()));
}