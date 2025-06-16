import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  
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
    _loadBannerAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지가 다시 보여질 때마다 데이터 새로고침
    _loadStatistics();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    // 광고 제거 구매 여부 확인
    final adRemoved = await AdService.isAdRemoved();
    if (adRemoved) {
      print('💰 광고 제거됨: 배너광고 로드 건너뜀');
      return;
    }

    _bannerAd = AdService.createBannerAd();
    _bannerAd!.load().then((_) {
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
      }
    });
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
              Container(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
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
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '습관 성취도와 경향을 확인하세요' :
                            localizations?.locale.languageCode == 'ja' ? '習慣の達成度と傾向を確認してください' : 'Check your habit achievements and trends',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _loadStatistics,
                        icon: const Icon(
                          Icons.refresh_rounded, 
                          color: Colors.white,
                        ),
                        tooltip: localizations?.locale.languageCode == 'ko' ? '새로고침' :
                                localizations?.locale.languageCode == 'ja' ? 'リフレッシュ' : 'Refresh',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
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
                            
                            // 전체 평균 완료율 표시
                            if (completionRates.isNotEmpty) ...[
                              Builder(
                                builder: (context) {
                                  final averageRate = completionRates.values.reduce((a, b) => a + b) / completionRates.length;
                                  final title = _getTitle(averageRate);
                                  final titleColor = _getTitleColor(averageRate);
                                  
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          titleColor.withOpacity(0.1),
                                          titleColor.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: titleColor.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${(averageRate * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          localizations?.locale.languageCode == 'ko' ? '전체 평균 완료율' :
                                          localizations?.locale.languageCode == 'ja' ? '全体平均完了率' : 'Overall Completion Rate',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: titleColor.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // 습관별 완료율 목록
                            ...completionRates.entries.map((entry) {
                              final rate = entry.value;
                              final color = _getRateColor(rate);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
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
                                            entry.key,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${(rate * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: rate,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      
                      // 배너광고를 위한 하단 여백
                      SizedBox(height: _isAdLoaded ? 100 : 20),
                    ],
                  ),
                ),
              ),
              
              // 하단 배너광고
              if (_isAdLoaded && _bannerAd != null)
                Container(
                  height: 60,
                  color: Colors.white,
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 