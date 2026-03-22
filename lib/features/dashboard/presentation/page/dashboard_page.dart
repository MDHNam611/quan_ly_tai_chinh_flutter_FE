import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:do_an_quan_ly_tai_chinh/features/dashboard/presentation/widgets/period_selection_modal.dart';
import 'package:do_an_quan_ly_tai_chinh/features/dashboard/presentation/state/dashboard_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  PeriodType _currentPeriodType = PeriodType.month;
  String _periodTitle = 'THÁNG ${DateTime.now().month} ${DateTime.now().year}';
  DateTime? _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboardDataRange(_startDate, _endDate);
  }

  // Hàm xử lý khi bấm 2 nút mũi tên qua lại
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

    // Load lại dữ liệu theo mốc thời gian mới
    context.read<DashboardCubit>().loadDashboardDataRange(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // Kiểm tra xem có đang ở chế độ khóa 2 mũi tên không
    final isArrowDisabled = _currentPeriodType == PeriodType.all || _currentPeriodType == PeriodType.custom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tổng quan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // THANH CHỌN KỲ (CÓ 2 MŨI TÊN)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mũi tên trái
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_left, color: isArrowDisabled ? Colors.grey.shade300 : Colors.grey), 
                  onPressed: isArrowDisabled ? null : () => _shiftPeriod(-1),
                ),
                
                // Nút chọn Kỳ ở giữa
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
                      context.read<DashboardCubit>().loadDashboardDataRange(_startDate, _endDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_periodTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                  ),
                ),

                // Mũi tên phải
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_right, color: isArrowDisabled ? Colors.grey.shade300 : Colors.grey), 
                  onPressed: isArrowDisabled ? null : () => _shiftPeriod(1),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1),
          
          // GIAO DIỆN HIỂN THỊ DỮ LIỆU
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) return const Center(child: CircularProgressIndicator());
                if (state is DashboardError) return Center(child: Text('Lỗi: ${state.message}'));
                
                if (state is DashboardLoaded) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // THẺ TÓM TẮT THU CHI
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                            border: Border.all(color: Colors.grey.shade200)
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Thu nhập', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  Text(currencyFormatter.format(state.totalIncome), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Divider(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Chi phí', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  Text(currencyFormatter.format(state.totalExpense), style: TextStyle(color: Colors.pink.shade400, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Divider(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    currencyFormatter.format(state.netBalance.abs()), 
                                    style: TextStyle(color: state.netBalance < 0 ? Colors.pink.shade400 : Colors.teal, fontWeight: FontWeight.bold, fontSize: 20)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // KHU VỰC CHỜ GẮN THƯ VIỆN BIỂU ĐỒ (fl_chart)
                        const Text('Biểu đồ chi phí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                          child: const Center(
                            child: Text('Khu vực gắn thư viện biểu đồ (fl_chart)', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          ),
                        )
                      ],
                    ),
                  );
                }
                return const SizedBox();
              }
            )
          )
        ],
      ),
    );
  }
}