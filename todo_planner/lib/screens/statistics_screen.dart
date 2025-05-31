import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/todo_item.dart';
import '../services/storage_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<TodoItem> _template = [];
  Map<String, Map<String, bool>> _statisticsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    // 현재 템플릿 로드
    final template = await StorageService.loadTemplate();
    
    // 템플릿 적용 날짜 확인
    final templateAppliedDate = await StorageService.getTemplateAppliedDate();
    
    // 통계 기간 설정 (템플릿 적용일 또는 6개월 전 중 더 늦은 날짜부터)
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    DateTime startDate = sixMonthsAgo;
    
    if (templateAppliedDate != null) {
      final appliedDate = DateTime.parse(templateAppliedDate);
      if (appliedDate.isAfter(sixMonthsAgo)) {
        startDate = appliedDate;
      }
    }

    // 통계 데이터 수집
    final statisticsData = <String, Map<String, bool>>{};
    
    for (DateTime date = startDate; 
         date.isBefore(now.add(const Duration(days: 1))); 
         date = date.add(const Duration(days: 1))) {
      
      final dateString = _formatDate(date);
      final dailyTodos = await StorageService.loadDailyData(dateString);
      
      final dayData = <String, bool>{};
      for (final todo in dailyTodos) {
        dayData[todo.title] = todo.isCompleted;
      }
      
      if (dayData.isNotEmpty) {
        statisticsData[dateString] = dayData;
      }
    }

    setState(() {
      _template = template;
      _statisticsData = statisticsData;
      _isLoading = false;
    });
  }

  Map<String, double> _calculateCompletionRates() {
    final rates = <String, double>{};
    
    for (final todoItem in _template) {
      int totalDays = 0;
      int completedDays = 0;
      
      for (final dayData in _statisticsData.values) {
        if (dayData.containsKey(todoItem.title)) {
          totalDays++;
          if (dayData[todoItem.title] == true) {
            completedDays++;
          }
        }
      }
      
      rates[todoItem.title] = totalDays > 0 ? completedDays / totalDays : 0.0;
    }
    
    return rates;
  }

  List<FlSpot> _getChartData() {
    final dailyRates = <String, double>{};
    
    for (final entry in _statisticsData.entries) {
      final date = entry.key;
      final dayData = entry.value;
      
      if (dayData.isNotEmpty) {
        final completedCount = dayData.values.where((completed) => completed).length;
        final totalCount = dayData.length;
        dailyRates[date] = completedCount / totalCount;
      }
    }
    
    final sortedDates = dailyRates.keys.toList()..sort();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < sortedDates.length; i++) {
      final rate = dailyRates[sortedDates[i]]!;
      spots.add(FlSpot(i.toDouble(), rate * 100));
    }
    
    return spots;
  }

  Color _getRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_template.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        '통계',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '할 일 완료율과 진행 상황을 확인하세요',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '템플릿을 먼저 설정해주세요',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final completionRates = _calculateCompletionRates();
    final chartData = _getChartData();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '통계',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '할 일 완료율과 진행 상황을 확인하세요',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _loadStatistics,
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        tooltip: '새로고침',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chart Section
                      if (chartData.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.trending_up_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '일별 완료율 추이',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 25,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.shade300,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          interval: 25,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${value.toInt()}%',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        left: BorderSide(color: Colors.grey.shade300),
                                        bottom: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: chartData.length.toDouble() - 1,
                                    minY: 0,
                                    maxY: 100,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: chartData,
                                        isCurved: true,
                                        color: Theme.of(context).colorScheme.primary,
                                        barWidth: 3,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.white,
                                              strokeWidth: 2,
                                              strokeColor: Theme.of(context).colorScheme.primary,
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Completion Rates Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.assignment_turned_in_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '항목별 완료율',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            if (completionRates.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    '통계 데이터가 없습니다.',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...completionRates.entries.map((entry) {
                                final title = entry.key;
                                final rate = entry.value;
                                final percentage = (rate * 100).toStringAsFixed(1);
                                final color = _getRateColor(rate);
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$percentage%',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: rate,
                                          backgroundColor: Colors.grey.shade300,
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Summary Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.summarize_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '요약',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow('분석 기간', '${_statisticsData.keys.isNotEmpty ? _statisticsData.keys.reduce((a, b) => a.compareTo(b) < 0 ? a : b) : "없음"} ~ ${_statisticsData.keys.isNotEmpty ? _statisticsData.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b) : "없음"}'),
                            _buildSummaryRow('총 분석 일수', '${_statisticsData.length}일'),
                            _buildSummaryRow('템플릿 항목 수', '${_template.length}개'),
                            if (completionRates.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow('평균 완료율', '${(completionRates.values.reduce((a, b) => a + b) / completionRates.length * 100).toStringAsFixed(1)}%'),
                              _buildSummaryRow('최고 완료율', '${(completionRates.values.reduce((a, b) => a > b ? a : b) * 100).toStringAsFixed(1)}%'),
                              _buildSummaryRow('최저 완료율', '${(completionRates.values.reduce((a, b) => a < b ? a : b) * 100).toStringAsFixed(1)}%'),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 