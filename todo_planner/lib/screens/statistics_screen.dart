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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_template.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('통계'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text(
            '템플릿을 먼저 설정해주세요.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final completionRates = _calculateCompletionRates();
    final chartData = _getChartData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 완료율 차트
            if (chartData.isNotEmpty) ...[
              const Text(
                '일별 완료율 추이',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%');
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
                    borderData: FlBorderData(show: true),
                    minX: 0,
                    maxX: chartData.length.toDouble() - 1,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            // 항목별 완료율 표
            const Text(
              '항목별 완료율',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (completionRates.isEmpty)
              const Text(
                '통계 데이터가 없습니다.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 헤더
                      const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              '할 일',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '완료율',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '진행률',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // 데이터 행들
                      ...completionRates.entries.map((entry) {
                        final title = entry.key;
                        final rate = entry.value;
                        final percentage = (rate * 100).toStringAsFixed(1);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  title,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '$percentage%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: rate >= 0.8 
                                        ? Colors.green 
                                        : rate >= 0.5 
                                            ? Colors.orange 
                                            : Colors.red,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: LinearProgressIndicator(
                                  value: rate,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    rate >= 0.8 
                                        ? Colors.green 
                                        : rate >= 0.5 
                                            ? Colors.orange 
                                            : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // 요약 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '요약',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text('분석 기간: ${_statisticsData.keys.isNotEmpty ? _statisticsData.keys.reduce((a, b) => a.compareTo(b) < 0 ? a : b) : "없음"} ~ ${_statisticsData.keys.isNotEmpty ? _statisticsData.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b) : "없음"}'),
                    Text('총 분석 일수: ${_statisticsData.length}일'),
                    Text('템플릿 항목 수: ${_template.length}개'),
                    if (completionRates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('평균 완료율: ${(completionRates.values.reduce((a, b) => a + b) / completionRates.length * 100).toStringAsFixed(1)}%'),
                      Text('최고 완료율: ${(completionRates.values.reduce((a, b) => a > b ? a : b) * 100).toStringAsFixed(1)}%'),
                      Text('최저 완료율: ${(completionRates.values.reduce((a, b) => a < b ? a : b) * 100).toStringAsFixed(1)}%'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 