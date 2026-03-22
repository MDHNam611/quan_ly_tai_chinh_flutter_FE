import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Enum định nghĩa các loại kỳ
enum PeriodType { custom, all, specificDay, week, today, year, month }

// Class chứa kết quả trả về
class PeriodFilter {
  final PeriodType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String title;

  PeriodFilter({required this.type, this.startDate, this.endDate, required this.title});
}

class PeriodSelectionModal extends StatefulWidget {
  final PeriodType currentType;
  
  const PeriodSelectionModal({super.key, required this.currentType});

  @override
  State<PeriodSelectionModal> createState() => _PeriodSelectionModalState();
}

class _PeriodSelectionModalState extends State<PeriodSelectionModal> {
  late PeriodType _selectedType;
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
  }

  // Hàm tính toán ngày đầu tuần và cuối tuần
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _selectPeriod(PeriodType type) async {
    DateTime? start;
    DateTime? end;
    String title = '';

    switch (type) {
      case PeriodType.all:
        title = 'Tất cả thời gian';
        break;
      case PeriodType.today:
        start = DateTime(_now.year, _now.month, _now.day);
        end = DateTime(_now.year, _now.month, _now.day, 23, 59, 59);
        title = '${_now.day} tháng ${_now.month}';
        break;
      case PeriodType.specificDay:
        final picked = await showDatePicker(context: context, initialDate: _now, firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked == null) return;
        start = DateTime(picked.year, picked.month, picked.day);
        end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        title = '${picked.day} tháng ${picked.month}';
        break;
      case PeriodType.week:
        start = _getStartOfWeek(_now);
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
        title = '${start.day} - ${end.day} thg ${start.month}';
        break;
      case PeriodType.month:
        start = DateTime(_now.year, _now.month, 1);
        end = DateTime(_now.year, _now.month + 1, 0, 23, 59, 59);
        title = 'Tháng ${_now.month} ${_now.year}';
        break;
      case PeriodType.year:
        start = DateTime(_now.year, 1, 1);
        end = DateTime(_now.year, 12, 31, 23, 59, 59);
        title = 'Năm ${_now.year}';
        break;
      case PeriodType.custom:
        final pickedRange = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (pickedRange == null) return;
        start = pickedRange.start;
        end = DateTime(pickedRange.end.year, pickedRange.end.month, pickedRange.end.day, 23, 59, 59);
        title = '${start.day}/${start.month} - ${end.day}/${end.month}';
        break;
    }

    if (context.mounted) {
      Navigator.pop(context, PeriodFilter(type: type, startDate: start, endDate: end, title: title));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text('Kỳ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildOption(icon: Icons.more_horiz, title: 'Chọn khoảng', subtitle: 'Tùy chỉnh', type: PeriodType.custom, isFullWidth: true),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // ĐÃ SỬA LỖI Ở ĐÂY
              crossAxisCount: 2,
              childAspectRatio: 2.2, 
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildOption(icon: Icons.all_inclusive, title: 'Tất cả thời gian', subtitle: '', type: PeriodType.all),
                _buildOption(icon: Icons.calendar_today, title: 'Chọn ngày', subtitle: '', type: PeriodType.specificDay),
                _buildOption(icon: Icons.calendar_view_week, title: 'Tuần', subtitle: '${_getStartOfWeek(_now).day} - ${_getStartOfWeek(_now).add(const Duration(days: 6)).day} thg ${_now.month}', type: PeriodType.week),
                _buildOption(icon: Icons.today, title: 'Hôm nay', subtitle: '${_now.day} tháng ${_now.month}', type: PeriodType.today),
                _buildOption(icon: Icons.calendar_month_outlined, title: 'Năm', subtitle: 'Năm ${_now.year}', type: PeriodType.year),
                _buildOption(icon: Icons.calendar_month, title: 'Tháng', subtitle: 'Tháng ${_now.month} ${_now.year}', type: PeriodType.month),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({required IconData icon, required String title, required String subtitle, required PeriodType type, bool isFullWidth = false}) {
    final isSelected = _selectedType == type;
    final bgColor = isSelected ? const Color(0xFFE8EAF6) : Colors.grey.shade50;

    return InkWell(
      onTap: () => _selectPeriod(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // ĐÃ SỬA: Giảm padding dọc
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isSelected ? Colors.black87 : Colors.black54), // ĐÃ SỬA: Giảm size icon
            const SizedBox(height: 2), // ĐÃ SỬA: Giảm khoảng cách
            Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis), // ĐÃ SỬA: Ép 1 dòng chống tràn
          ],
        ),
      ),
    );
  }
}