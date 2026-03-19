import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/widgets/category_management_modal.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Danh mục', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87), // Cây bút chì
            onPressed: () {
              // Mở giao diện CRUD Danh mục
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
            },
          )
        ],
      ),
      // Lồng 2 BlocBuilder để lấy cả Danh sách danh mục lẫn Dữ liệu giao dịch tính tổng tiền
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, catState) {
          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              if (catState is CategoryLoaded && txState is TransactionLoaded) {
                // 1. Tính toán tổng tiền theo từng danh mục Chi phí
                double totalExpense = 0;
                Map<String, double> expenseAmounts = {};
                
                for (var tx in txState.transactions) {
                  if (tx.type == 'expense') {
                    totalExpense += tx.amount;
                    expenseAmounts[tx.category] = (expenseAmounts[tx.category] ?? 0) + tx.amount;
                  }
                }

                // 2. Tạo dữ liệu cho PieChart
                List<PieChartSectionData> pieSections = [];
                for (var cat in catState.expenseCategories) {
                  final amount = expenseAmounts[cat.name] ?? 0;
                  if (amount > 0) {
                    pieSections.add(PieChartSectionData(
                      color: CategoryHelper.getColor(cat.color),
                      value: amount,
                      title: '', // Ẩn chữ trên viền
                      radius: 15,
                    ));
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Vòng tròn trung tâm
                      if (totalExpense > 0)
                        SizedBox(
                          height: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(PieChartData(sections: pieSections, centerSpaceRadius: 80, sectionsSpace: 4)),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Chi phí', style: TextStyle(fontSize: 16, color: Colors.black87)),
                                  Text(currencyFormatter.format(totalExpense), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink.shade400)),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        const Padding(padding: EdgeInsets.all(32.0), child: Text('Chưa có chi phí nào trong tháng này')),

                      const SizedBox(height: 32),
                      
                      // Lưới danh mục bên dưới
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: catState.expenseCategories.map((cat) {
                          final amount = expenseAmounts[cat.name] ?? 0;
                          return SizedBox(
                            width: 80,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: CategoryHelper.getColor(cat.color).withOpacity(0.15),
                                  child: Icon(CategoryHelper.getIcon(cat.icon), color: CategoryHelper.getColor(cat.color), size: 28),
                                ),
                                const SizedBox(height: 8),
                                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(currencyFormatter.format(amount), style: TextStyle(color: CategoryHelper.getColor(cat.color), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          );
        },
      ),
    );
  }
}