import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/todo_item.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with AutomaticKeepAliveClientMixin {
  List<TodoItem> _template = [];
  Map<String, Map<String, bool>> _statisticsData = {};
  bool _isLoading = true;
  
  // 외부에서 새로고침을 호출할 수 있는 공개 메서드
  void refresh() {
    _loadStatistics();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지가 다시 보여질 때마다 데이터 새로고침
    _loadStatistics();
    // 통계 화면 진입 시 광고 표시
    _showAdOnStatisticsView();
  }

  Future<void> _showAdOnStatisticsView() async {
    // 잠시 후 광고 표시 (UI 로딩 후)
    await Future.delayed(const Duration(milliseconds: 500));
    await AdService.showInterstitialAd();
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
    
    // 최근 30일간의 통계 기간 설정 (29일 전부터 오늘까지)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));
    DateTime startDate = thirtyDaysAgo;

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

  String _getTitle(double averageRate) {
    if (averageRate >= 0.95) return "Perfectionist";
    if (averageRate >= 0.90) return "Iron Will";
    if (averageRate >= 0.85) return "Diligent";
    if (averageRate >= 0.80) return "Hardworking";
    if (averageRate >= 0.75) return "Industrious";
    if (averageRate >= 0.70) return "Consistent";
    if (averageRate >= 0.65) return "Trying";
    if (averageRate >= 0.60) return "Attempting";
    if (averageRate >= 0.50) return "Lazy";
    if (averageRate >= 0.30) return "Sluggish";
    if (averageRate >= 0.10) return "Lethargic";
    return "Sleeper";
  }

  Color _getTitleColor(double averageRate) {
    if (averageRate >= 0.90) return Colors.purple.shade700;
    if (averageRate >= 0.80) return Colors.blue.shade700;
    if (averageRate >= 0.70) return Colors.green.shade700;
    if (averageRate >= 0.60) return Colors.orange.shade700;
    if (averageRate >= 0.50) return Colors.red.shade600;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    final localizations = AppLocalizations.of(context);
    
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
                // Header with Refresh Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations?.locale.languageCode == 'ko' ? '통계' :
                              localizations?.locale.languageCode == 'ja' ? '統計' : 'Statistics',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizations?.locale.languageCode == 'ko' ? '습관 완료율과 진행 상황을 확인하세요' :
                              localizations?.locale.languageCode == 'ja' ? '習慣完了率と進行状況を 확인하세요' : 'Check your habit completion rates and progress',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
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
                          localizations?.locale.languageCode == 'ko' ? '템플릿을 설정하고 새로고침을 눌러주세요' :
                          localizations?.locale.languageCode == 'ja' ? 'テンプレートを設定してリフレッシュを押してください' : 'Set up templates and tap refresh',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadStatistics,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(localizations?.locale.languageCode == 'ko' ? '새로고침' :
                                     localizations?.locale.languageCode == 'ja' ? 'リフレッシュ' : 'Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
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
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '통계' :
                            localizations?.locale.languageCode == 'ja' ? '統計' : 'Statistics',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '습관 완료율과 진행 상황을 확인하세요' :
                            localizations?.locale.languageCode == 'ja' ? '習慣完了率と進行状況を確認しましょう' : 'Check your habit completion rates and progress',
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
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _loadStatistics,
                        icon: Icon(
                          Icons.refresh_rounded, 
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: localizations?.locale.languageCode == 'ko' ? '새로고침' :
                                localizations?.locale.languageCode == 'ja' ? 'リフレッシュ' : 'Refresh',
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
                                  Text(
                                    localizations?.locale.languageCode == 'ko' ? '일별 완료율 추이' :
                                    localizations?.locale.languageCode == 'ja' ? '日別完了率推移' : 'Daily Completion Trend',
                                    style: const TextStyle(
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
                                Text(
                                  localizations?.locale.languageCode == 'ko' ? '습관별 완료율' :
                                  localizations?.locale.languageCode == 'ja' ? '習慣別完了率' : 'Habit Completion Rates',
                                  style: const TextStyle(
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
                                    localizations?.locale.languageCode == 'ko' ? '통계 데이터가 없습니다.' :
                                    localizations?.locale.languageCode == 'ja' ? '統計データが見つかりません。' : 'No statistics data found.',
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
                                Text(
                                  localizations?.locale.languageCode == 'ko' ? '요약' :
                                  localizations?.locale.languageCode == 'ja' ? '要約' : 'Summary',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow(
                              localizations?.locale.languageCode == 'ko' ? '분석 기간' :
                              localizations?.locale.languageCode == 'ja' ? '分析期間' : 'Analysis Period',
                              localizations?.locale.languageCode == 'ko' ? '최근 30일 (${_statisticsData.keys.isNotEmpty ? _statisticsData.keys.reduce((a, b) => a.compareTo(b) < 0 ? a : b) : "없음"} ~ ${_formatDate(DateTime.now())})' :
                              localizations?.locale.languageCode == 'ja' ? '最近30日 (${_statisticsData.keys.isNotEmpty ? _statisticsData.keys.reduce((a, b) => a.compareTo(b) < 0 ? a : b) : "なし"} ~ ${_formatDate(DateTime.now())})' : 'Last 30 days (${_statisticsData.keys.isNotEmpty ? _statisticsData.keys.reduce((a, b) => a.compareTo(b) < 0 ? a : b) : "None"} ~ ${_formatDate(DateTime.now())})'
                            ),
                            _buildSummaryRow(
                              localizations?.locale.languageCode == 'ko' ? '총 분석 일수' :
                              localizations?.locale.languageCode == 'ja' ? '総分析日数' : 'Total Analysis Days',
                              localizations?.locale.languageCode == 'ko' ? '${_statisticsData.length}일' :
                              localizations?.locale.languageCode == 'ja' ? '${_statisticsData.length}日' : '${_statisticsData.length} days'
                            ),
                            _buildSummaryRow(
                              localizations?.locale.languageCode == 'ko' ? '템플릿 항목 수' :
                              localizations?.locale.languageCode == 'ja' ? 'テンプレート項目数' : 'Template Items',
                              localizations?.locale.languageCode == 'ko' ? '${_template.length}개' :
                              localizations?.locale.languageCode == 'ja' ? '${_template.length}個' : '${_template.length} habits'
                            ),
                            if (completionRates.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                localizations?.locale.languageCode == 'ko' ? '평균 완료율' :
                                localizations?.locale.languageCode == 'ja' ? '平均完了率' : 'Average Completion Rate',
                                '${(completionRates.values.reduce((a, b) => a + b) / completionRates.length * 100).toStringAsFixed(1)}%'
                              ),
                              _buildSummaryRow(
                                localizations?.locale.languageCode == 'ko' ? '최고 완료율' :
                                localizations?.locale.languageCode == 'ja' ? '最高完了率' : 'Highest Completion Rate',
                                '${(completionRates.values.reduce((a, b) => a > b ? a : b) * 100).toStringAsFixed(1)}%'
                              ),
                              _buildSummaryRow(
                                localizations?.locale.languageCode == 'ko' ? '최저 완료율' :
                                localizations?.locale.languageCode == 'ja' ? '最低完了率' : 'Lowest Completion Rate',
                                '${(completionRates.values.reduce((a, b) => a < b ? a : b) * 100).toStringAsFixed(1)}%'
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getTitleColor(completionRates.values.reduce((a, b) => a + b) / completionRates.length).withOpacity(0.1),
                                      _getTitleColor(completionRates.values.reduce((a, b) => a + b) / completionRates.length).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getTitleColor(completionRates.values.reduce((a, b) => a + b) / completionRates.length).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.military_tech_rounded,
                                      color: _getTitleColor(completionRates.values.reduce((a, b) => a + b) / completionRates.length),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      localizations?.locale.languageCode == 'ko' ? '칭호' :
                                      localizations?.locale.languageCode == 'ja' ? '称号' : 'Title',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '"${_getTitle(completionRates.values.reduce((a, b) => a + b) / completionRates.length)}"',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _getTitleColor(completionRates.values.reduce((a, b) => a + b) / completionRates.length),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Ad Removal Purchase Section (주석처리)
                      /*
                      FutureBuilder<bool>(
                        future: AdService.isAdRemoved(),
                        builder: (context, snapshot) {
                          final isAdRemoved = snapshot.data ?? false;
                          
                          if (isAdRemoved) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      '광고가 제거되었습니다!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return Container(
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
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      '프리미엄 업그레이드',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '광고 없는 깔끔한 환경에서 습관을 관리하세요!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await PurchaseService.purchaseRemoveAds();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('구매 요청이 처리되었습니다.'),
                                              backgroundColor: Colors.green.shade600,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('구매 중 오류가 발생했습니다: $e'),
                                              backgroundColor: Colors.red.shade600,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.shopping_cart_rounded),
                                    label: Text('광고 제거하기 - ${PurchaseService.getRemoveAdsPrice()}'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.amber.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed: () async {
                                      try {
                                        await PurchaseService.restorePurchases();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('구매 복원이 완료되었습니다.'),
                                              backgroundColor: Colors.blue.shade600,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('복원 중 오류가 발생했습니다: $e'),
                                              backgroundColor: Colors.red.shade600,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Text(
                                      '구매 복원',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      */
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