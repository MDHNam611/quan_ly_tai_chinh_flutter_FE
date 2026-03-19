import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartWidget extends StatelessWidget {
  final Map<int, double> dailyExpenses;

  const BarChartWidget({super.key, required this.dailyExpenses});

  @override
  Widget build(BuildContext context) {
    // Tìm giá trị chi tiêu lớn nhất trong tháng để chia tỷ lệ trục Y
    double maxExpense = 0;
    dailyExpenses.forEach((key, value) {
      if (value > maxExpense) maxExpense = value;
    });

    // Nếu không có chi tiêu nào, hiển thị biểu đồ rỗng một cách mượt mà
    if (maxExpense == 0) maxExpense = 100000; 

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxExpense,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  // Chỉ hiển thị nhãn cho các ngày 1, 9, 16, 23, 31 giống thiết kế
                  const style = TextStyle(color: Colors.grey, fontSize: 10);
                  Widget text;
                  switch (value.toInt()) {
                    case 1: text = const Text('1', style: style); break;
                    case 9: text = const Text('9', style: style); break;
                    case 16: text = const Text('16', style: style); break;
                    case 23: text = const Text('23', style: style); break;
                    case 31: text = const Text('31', style: style); break;
                    default: text = const Text('', style: style); break;
                  }
                  return SideTitleWidget(meta: meta, space: 4, child: text);
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxExpense / 2, // Hiển thị đường kẻ ngang ở mốc 50% và 100%
            getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1, dashArray: [5, 5]),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailyExpenses.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: entry.value > 0 ? Colors.pink.shade400 : Colors.transparent, // Cột màu hồng nếu có chi tiêu
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}