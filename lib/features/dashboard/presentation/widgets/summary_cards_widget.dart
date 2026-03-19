import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCardsWidget extends StatelessWidget {
  final double income;
  final double expense;

  const SummaryCardsWidget({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.pink.shade400, // Màu hồng/đỏ cho Chi phí theo thiết kế
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                const Text('Chi phí', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(expense),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50, // Màu xanh nhạt cho Thu nhập
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                const Text('Thu nhập', style: TextStyle(color: Colors.teal, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(income),
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}