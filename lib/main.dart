import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;
import 'features/transactions/presentation/state/transaction_cubit.dart';
import 'features/transactions/presentation/pages/main_layout.dart';
import 'features/accounts/presentation/state/account_cubit.dart';
import 'features/dashboard/presentation/state/dashboard_cubit.dart';
import 'features/categories/presentation/state/category_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:do_an_quan_ly_tai_chinh/features/auth/presentation/state/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);
  
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<TransactionCubit>()..loadTransactions()),
        BlocProvider(create: (_) => di.sl<AccountCubit>()..loadAccounts()),
        BlocProvider(create: (_) => di.sl<DashboardCubit>()), // Khởi tạo Cubit Dashboard
        BlocProvider(create: (_) => di.sl<CategoryCubit>()..loadCategories()),
        BlocProvider(create: (_) => di.sl<AuthCubit>()..checkAuthStatus()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quản Lý Tài Chính',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const MainLayout(),
      ),
    );
  }
}