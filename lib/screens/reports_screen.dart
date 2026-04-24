import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:water_tracker_mobile/theme/app_theme.dart';
import 'package:water_tracker_mobile/services/database_helper.dart';
import 'package:water_tracker_mobile/services/report_service.dart';
import 'package:intl/intl.dart' as intl;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _dailyStats = [];
  Map<String, dynamic> _summary = {
    'totalPassengers': 0,
    'totalBottles': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final monthStr = intl.DateFormat('yyyy-MM').format(_selectedMonth);
    final stats = await DatabaseHelper().getDailyStatsForMonth(monthStr);
    
    int totalP = 0;
    int totalB = 0;
    for (var s in stats) {
      totalP += (s['totalPassengers'] as num?)?.toInt() ?? 0;
      totalB += (s['totalBottles'] as num?)?.toInt() ?? 0;
    }

    if (mounted) {
      setState(() {
        _dailyStats = stats;
        _summary = {
          'totalPassengers': totalP,
          'totalBottles': totalB,
        };
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
    _loadReportData();
  }

  String _getMonthName() {
    return intl.DateFormat('MMMM yyyy', 'ar').format(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('تقارير الشهر'),
        actions: [
          IconButton(
            onPressed: () => ReportService.generateMonthlyReport(
              monthName: _getMonthName(),
              dailyStats: _dailyStats,
            ),
            icon: const Icon(LucideIcons.printer, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadReportData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildTableSection(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          Column(
            children: [
              Text(
                'التقرير الشهري لـ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                 _getMonthName(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'إجمالي المسافرين',
            '${_summary['totalPassengers']}',
            LucideIcons.users,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'إجمالي القنينات',
            '${_summary['totalBottles']}',
            LucideIcons.droplets,
            Colors.green,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildTableSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'التوزيع اليومي',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('اليوم', textAlign: TextAlign.right)),
              DataColumn(label: Text('مسافرين', textAlign: TextAlign.right)),
              DataColumn(label: Text('قنينات', textAlign: TextAlign.right)),
            ],
            rows: _dailyStats.map((stat) {
              return DataRow(cells: [
                DataCell(Text(stat['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Center(child: Text('${stat['totalPassengers'] ?? 0}'))),
                DataCell(Center(child: Text('${stat['totalBottles'] ?? 0}'))),
              ]);
            }).toList(),
          ),
          if (_dailyStats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('لا توجد بيانات لهذا الشهر'),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}
