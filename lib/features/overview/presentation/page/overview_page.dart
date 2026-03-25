import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:uuid/uuid.dart';

import 'package:do_an_quan_ly_tai_chinh/core/helpers/icon_helper.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/presentation/state/account_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/accounts/data/models/account_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/presentation/state/category_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/categories/data/models/category_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/data/models/transaction_model.dart';
import 'package:do_an_quan_ly_tai_chinh/features/dashboard/presentation/widgets/period_selection_modal.dart';

import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/pages/transaction_page.dart';
import 'package:do_an_quan_ly_tai_chinh/features/transactions/presentation/widgets/transaction_search_modal.dart';

// ĐÃ THÊM: Import CustomAppBar
import 'package:do_an_quan_ly_tai_chinh/core/widgets/custom_app_bar.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  PeriodType _currentPeriodType = PeriodType.month;
  String _periodTitle = 'THÁNG ${DateTime.now().month} ${DateTime.now().year}';
  DateTime? _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  bool _isExpenseTab = true;

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

  double _calculateTotal(List<TransactionModel> txs, String type) {
    return txs.where((t) => t.type == type).fold(0.0, (sum, item) => sum + item.amount);
  }

  double _calculateToday(List<TransactionModel> txs, String type) {
    final now = DateTime.now();
    return txs.where((t) {
      if (t.type != type) return false;
      final d = DateTime.parse(t.date);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  double _calculateThisWeek(List<TransactionModel> txs, String type) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return txs.where((t) {
      if (t.type != type) return false;
      final d = DateTime.parse(t.date);
      return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && d.isBefore(endOfWeek.add(const Duration(seconds: 1)));
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  double _calculateDailyAvg(double totalAmount) {
    if (_startDate == null || _endDate == null || totalAmount == 0) return 0;
    final now = DateTime.now();
    int daysToDivide = 1;
    if (_startDate!.year == now.year && _startDate!.month == now.month) {
      daysToDivide = now.day;
    } else if (_endDate!.isBefore(now)) {
      daysToDivide = _endDate!.difference(_startDate!).inDays + 1;
    }
    return totalAmount / (daysToDivide > 0 ? daysToDivide : 1);
  }

  List<BarChartGroupData> _generateBarChartData(List<TransactionModel> txs, String type, double maxAmount) {
    if (_startDate == null || _endDate == null) return [];
    Map<int, double> dailyTotals = {};
    int daysInPeriod = _endDate!.difference(_startDate!).inDays + 1;
    if (daysInPeriod > 31) daysInPeriod = 31; 

    for (int i = 1; i <= daysInPeriod; i++) { dailyTotals[i] = 0.0; }

    for (var tx in txs) {
      if (tx.type == type) {
        final d = DateTime.parse(tx.date);
        if (d.month == _startDate!.month && d.year == _startDate!.year) {
           dailyTotals[d.day] = (dailyTotals[d.day] ?? 0) + tx.amount;
        }
      }
    }

    final barColor = type == 'expense' ? Colors.pink.shade400 : Colors.teal;
    final bgColor = Colors.grey.shade200;

    List<BarChartGroupData> barGroups = [];
    dailyTotals.forEach((day, amount) {
      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: barColor,
              width: 8,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxAmount == 0 ? 100 : maxAmount,
                color: bgColor,
              )
            ),
          ],
        )
      );
    });
    return barGroups;
  }

  void _showCategoryDetails(CategoryModel category, double amount, double percentage, int txCount, double totalOfType, String typeString) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    String actionLabel = typeString == 'expense' ? 'Chi phí' : 'Thu nhập';
    IconData actionIcon = typeString == 'expense' ? Icons.arrow_downward : Icons.arrow_upward;
    Color actionColor = typeString == 'expense' ? Colors.pink.shade300 : Colors.teal.shade400;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.blue.shade700,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$txCount giao dịch', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    Text(currencyFormatter.format(amount), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_periodTitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(currencyFormatter.format(totalOfType), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomSheetButton(
                      icon: actionIcon, 
                      color: actionColor, 
                      label: actionLabel, 
                      onTap: () {
                        Navigator.pop(ctx); 
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (innerCtx) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: context.read<TransactionCubit>()),
                              BlocProvider.value(value: context.read<AccountCubit>()),
                              BlocProvider.value(value: context.read<CategoryCubit>()),
                            ],
                            child: AddTransactionForm(
                              initialType: typeString, 
                              initialCategory: category.name 
                            ),
                          ),
                        );
                      }
                    ),
                    
                    _buildBottomSheetButton(
                      icon: Icons.receipt_long, 
                      color: Colors.blue.shade300, 
                      label: 'Giao dịch', 
                      onTap: () {
                        Navigator.pop(ctx); 
                        final filter = TransactionFilter(categories: [category.name], type: typeString);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPage(initialFilter: filter)));
                      }
                    ),
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

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isArrowDisabled = _currentPeriodType == PeriodType.all || _currentPeriodType == PeriodType.custom;
    
    String dayBoxText = '31';
    if (_currentPeriodType == PeriodType.month && _endDate != null) {
      dayBoxText = _endDate!.day.toString();
    } else if (_startDate != null) {
      dayBoxText = _startDate!.day.toString();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), 
      
      // ĐÃ SỬA: SỬ DỤNG CUSTOM APP BAR TẠI ĐÂY
      appBar: CustomAppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: () {})
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_left, color: isArrowDisabled ? Colors.grey.shade400 : Colors.black54, size: 28), 
                  onPressed: isArrowDisabled ? null : () => _shiftPeriod(-1)
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 1.2), borderRadius: BorderRadius.circular(6)),
                          child: Text(dayBoxText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        ),
                        const SizedBox(width: 8),
                        Text(_periodTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_right, color: isArrowDisabled ? Colors.grey.shade400 : Colors.black54, size: 28), 
                  onPressed: isArrowDisabled ? null : () => _shiftPeriod(1)
                ),
              ],
            ),
          ),
          
          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              double netBalance = 0;
              if (txState is TransactionLoaded) {
                 final filtered = txState.transactions.where((tx) {
                    final d = DateTime.parse(tx.date);
                    if (_startDate != null && _endDate != null) {
                      return d.isAfter(_startDate!.subtract(const Duration(seconds: 1))) && d.isBefore(_endDate!.add(const Duration(seconds: 1)));
                    }
                    return true;
                 }).toList();
                 double inc = _calculateTotal(filtered, 'income');
                 double exp = _calculateTotal(filtered, 'expense');
                 netBalance = inc - exp;
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFFF5F6FA),
                child: Column(
                  children: [
                    const Text('Số dư', style: TextStyle(color: Colors.black54, fontSize: 14)),
                    Text(
                      currencyFormatter.format(netBalance),
                      style: TextStyle(color: netBalance < 0 ? Colors.pink.shade400 : Colors.teal, fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  ],
                ),
              );
            }
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: BlocBuilder<TransactionCubit, TransactionState>(
                      builder: (context, txState) {
                        double totalInc = 0; double totalExp = 0;
                        if (txState is TransactionLoaded) {
                          final filtered = txState.transactions.where((tx) {
                            final d = DateTime.parse(tx.date);
                            if (_startDate != null && _endDate != null) {
                              return d.isAfter(_startDate!.subtract(const Duration(seconds: 1))) && d.isBefore(_endDate!.add(const Duration(seconds: 1)));
                            }
                            return true;
                        }).toList();
                        totalInc = _calculateTotal(filtered, 'income');
                        totalExp = _calculateTotal(filtered, 'expense');
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _isExpenseTab = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: _isExpenseTab ? Colors.pink.shade400 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Column(
                                    children: [
                                      Text('Chi phí', style: TextStyle(color: _isExpenseTab ? Colors.white : Colors.black54)),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(currencyFormatter.format(totalExp), style: TextStyle(color: _isExpenseTab ? Colors.white : Colors.pink.shade400, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _isExpenseTab = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: !_isExpenseTab ? Colors.teal : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Column(
                                    children: [
                                      Text('Thu nhập', style: TextStyle(color: !_isExpenseTab ? Colors.white : Colors.black54)),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(currencyFormatter.format(totalInc), style: TextStyle(color: !_isExpenseTab ? Colors.white : Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ),
                          ],
                        );
                      }
                    ),
                  ),

                  Expanded(
                    child: BlocBuilder<TransactionCubit, TransactionState>(
                      builder: (context, txState) {
                        return BlocBuilder<CategoryCubit, CategoryState>(
                          builder: (context, catState) {
                            if (txState is TransactionLoading || catState is CategoryLoading) return const Center(child: CircularProgressIndicator());
                            
                            if (txState is TransactionLoaded && catState is CategoryLoaded) {
                              final filteredTxs = txState.transactions.where((tx) {
                                final d = DateTime.parse(tx.date);
                                if (_startDate != null && _endDate != null) {
                                  return d.isAfter(_startDate!.subtract(const Duration(seconds: 1))) && d.isBefore(_endDate!.add(const Duration(seconds: 1)));
                                }
                                return true;
                              }).toList();

                              final typeString = _isExpenseTab ? 'expense' : 'income';
                              final themeColor = _isExpenseTab ? Colors.pink.shade400 : Colors.teal;
                              
                              final typeTotal = _calculateTotal(filteredTxs, typeString);
                              final todayTotal = _calculateToday(txState.transactions, typeString); 
                              final weekTotal = _calculateThisWeek(txState.transactions, typeString);
                              final dailyAvg = _calculateDailyAvg(typeTotal);

                              double maxDailyAmount = 0;
                              if (filteredTxs.isNotEmpty) {
                                Map<int, double> dailyTotals = {};
                                for (var tx in filteredTxs.where((t) => t.type == typeString)) {
                                  int day = DateTime.parse(tx.date).day;
                                  dailyTotals[day] = (dailyTotals[day] ?? 0) + tx.amount;
                                  if (dailyTotals[day]! > maxDailyAmount) maxDailyAmount = dailyTotals[day]!;
                                }
                              }

                              final allCategories = _isExpenseTab ? catState.expenseCategories : catState.incomeCategories;
                              List<Map<String, dynamic>> categoryStats = [];
                              for (var cat in allCategories) {
                                double catAmount = filteredTxs.where((t) => t.category == cat.name && t.type == typeString).fold(0.0, (s, t) => s + t.amount);
                                int txCount = filteredTxs.where((t) => t.category == cat.name && t.type == typeString).length;
                                if (catAmount > 0) {
                                  categoryStats.add({
                                    'model': cat,
                                    'amount': catAmount,
                                    'percentage': (catAmount / typeTotal) * 100,
                                    'count': txCount,
                                  });
                                }
                              }
                              categoryStats.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Container(
                                      height: 180,
                                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                                      child: BarChart(
                                        BarChartData(
                                          alignment: BarChartAlignment.spaceAround,
                                          maxY: maxDailyAmount == 0 ? 100 : maxDailyAmount,
                                          barTouchData: BarTouchData(enabled: false),
                                          titlesData: FlTitlesData(
                                            show: true,
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (double value, TitleMeta meta) {
                                                  int day = value.toInt();
                                                  if (day == 1 || day == 9 || day == 16 || day == 23 || day == 31) {
                                                    return Padding(padding: const EdgeInsets.only(top: 4), child: Text(day == 1 || day == 31 ? '$day th${_startDate?.month ?? ''}' : '$day', style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                                  }
                                                  return const SizedBox();
                                                },
                                              ),
                                            ),
                                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          ),
                                          gridData: FlGridData(
                                            show: true, 
                                            drawVerticalLine: true,
                                            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1, dashArray: [4, 4]),
                                            getDrawingVerticalLine: (value) => FlLine(color: Colors.transparent),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          barGroups: _generateBarChartData(filteredTxs, typeString, maxDailyAmount),
                                        )
                                      ),
                                    ),

                                    Container(
                                      color: themeColor.withOpacity(0.05),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      margin: const EdgeInsets.only(top: 16),
                                      child: Row(
                                        children: [
                                          Expanded(child: Column(children: [const Text('Ngày (tb)', style: TextStyle(color: Colors.black87)), FittedBox(fit: BoxFit.scaleDown, child: Text(currencyFormatter.format(dailyAvg), style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)))])),
                                          Container(width: 1, height: 30, color: Colors.grey.shade300),
                                          Expanded(child: Column(children: [const Text('Hôm nay', style: TextStyle(color: Colors.black87)), FittedBox(fit: BoxFit.scaleDown, child: Text(currencyFormatter.format(todayTotal), style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)))])),
                                          Container(width: 1, height: 30, color: Colors.grey.shade300),
                                          Expanded(child: Column(children: [const Text('Tuần', style: TextStyle(color: Colors.black87)), FittedBox(fit: BoxFit.scaleDown, child: Text(currencyFormatter.format(weekTotal), style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)))])),
                                        ],
                                      ),
                                    ),

                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.all(16),
                                      itemCount: categoryStats.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final item = categoryStats[index];
                                        final cat = item['model'] as CategoryModel;
                                        final amount = item['amount'] as double;
                                        final percentage = item['percentage'] as double;
                                        final count = item['count'] as int;

                                        return InkWell(
                                          onTap: () => _showCategoryDetails(cat, amount, percentage, count, typeTotal, typeString),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: CategoryHelper.getColor(cat.color),
                                                child: Icon(CategoryHelper.getIcon(cat.icon), color: Colors.white),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(cat.name, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                                        Text(currencyFormatter.format(amount), style: const TextStyle(fontSize: 16, color: Colors.black54)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(4),
                                                            child: LinearProgressIndicator(
                                                              value: percentage / 100,
                                                              backgroundColor: Colors.grey.shade200,
                                                              valueColor: AlwaysStoppedAnimation<Color>(CategoryHelper.getColor(cat.color)),
                                                              minHeight: 6,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    )
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
            ),
          )
        ],
      ),
    );
  }
}

// =========================================================
// FORM THÊM GIAO DỊCH (Nhúng vào để dùng cục bộ)
// =========================================================
class AddTransactionForm extends StatefulWidget {
  final String? initialAccountId;
  final String? initialType;
  final String? initialCategory;

  const AddTransactionForm({super.key, this.initialAccountId, this.initialType, this.initialCategory});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _type;
  String? _category;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'expense';
    _category = widget.initialCategory;
    _accountId = widget.initialAccountId;
  }

  void _save() {
    if (_amountController.text.isEmpty || _accountId == null || _category == null) return;

    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount <= 0) return;

    final newTx = TransactionModel(
      accountId: _accountId!,
      category: _category!,
      type: _type,
      amount: amount,
      note: _noteController.text,
      date: DateTime.now().toIso8601String(),
      offlineId: const Uuid().v4(),
    );

    context.read<TransactionCubit>().addTransaction(newTx);
    context.read<AccountCubit>().loadAccounts();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accountState = context.read<AccountCubit>().state;
    List<AccountModel> accounts = accountState is AccountLoaded ? accountState.accounts : [];
    if (accounts.isNotEmpty && (_accountId == null || !accounts.any((a) => a.id == _accountId))) {
      _accountId = accounts.first.id;
    }

    final categoryState = context.read<CategoryCubit>().state;
    List<String> categories = [];
    if (categoryState is CategoryLoaded) {
      categories = _type == 'expense' 
          ? categoryState.expenseCategories.map((c) => c.name).toList()
          : categoryState.incomeCategories.map((c) => c.name).toList();
    }
    if (categories.isNotEmpty && (_category == null || !categories.contains(_category))) {
      _category = categories.first;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thêm giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: RadioListTile<String>(title: const Text('Chi'), value: 'expense', groupValue: _type, onChanged: (val) => setState(() { _type = val!; _category = null; }))),
              Expanded(child: RadioListTile<String>(title: const Text('Thu'), value: 'income', groupValue: _type, onChanged: (val) => setState(() { _type = val!; _category = null; }))),
            ],
          ),
          if (accounts.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _accountId,
              items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
              onChanged: (val) => setState(() => _accountId = val),
              decoration: const InputDecoration(labelText: 'Tài khoản', border: OutlineInputBorder()),
            )
          else const Text('Vui lòng tạo tài khoản trước', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          if (categories.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _category,
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _category = val),
              decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
            )
          else const Text('Vui lòng tạo danh mục trước', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          TextField(controller: _amountController, keyboardType: TextInputType.number, autofocus: true, decoration: const InputDecoration(labelText: 'Số tiền', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.note), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: accounts.isEmpty || categories.isEmpty ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6C4FF)), child: const Text('Lưu', style: TextStyle(color: Colors.black)))),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}