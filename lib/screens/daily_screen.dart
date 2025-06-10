import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> with AutomaticKeepAliveClientMixin {
  
  // 외부에서 새로고침을 호출할 수 있는 공개 메서드
  void refresh() {
    _loadDailyData();
  }
  DateTime _selectedDate = DateTime.now();
  List<TodoItem> _dailyTodos = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
    StorageService.cleanOldData(); // 앱 시작시 오래된 데이터 정리
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지가 다시 보여질 때마다 데이터 새로고침
    _loadDailyData();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDailyData() async {
    setState(() {
      _isLoading = true;
    });

    final dateString = _formatDate(_selectedDate);
    final todos = await StorageService.loadDailyData(dateString);
    
    setState(() {
      _dailyTodos = todos;
      _isLoading = false;
    });
  }

  Future<void> _saveDailyData() async {
    final dateString = _formatDate(_selectedDate);
    await StorageService.saveDailyData(dateString, _dailyTodos);
  }

  void _toggleTodoCompletion(int index) {
    setState(() {
      _dailyTodos[index] = _dailyTodos[index].copyWith(
        isCompleted: !_dailyTodos[index].isCompleted,
      );
    });
    _saveDailyData();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    final oneMonthLater = now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: sixMonthsAgo,
      lastDate: oneMonthLater,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyData();
    }
  }

  String _getDateDisplayText(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    if (selected == today) {
      return localizations?.locale.languageCode == 'ko' ? '오늘' :
             localizations?.locale.languageCode == 'ja' ? '今日' : 'Today';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return localizations?.locale.languageCode == 'ko' ? '어제' :
             localizations?.locale.languageCode == 'ja' ? '昨日' : 'Yesterday';
    } else if (selected == today.add(const Duration(days: 1))) {
      return localizations?.locale.languageCode == 'ko' ? '내일' :
             localizations?.locale.languageCode == 'ja' ? '明日' : 'Tomorrow';
    } else {
      List<String> weekdays;
      if (localizations?.locale.languageCode == 'ko') {
        weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final weekday = weekdays[_selectedDate.weekday - 1];
        return '${_selectedDate.month}월 ${_selectedDate.day}일 ($weekday)';
      } else if (localizations?.locale.languageCode == 'ja') {
        weekdays = ['月', '火', '水', '木', '金', '土', '日'];
        final weekday = weekdays[_selectedDate.weekday - 1];
        return '${_selectedDate.month}月${_selectedDate.day}日 ($weekday)';
      } else {
        weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final weekday = weekdays[_selectedDate.weekday - 1];
        return '${_selectedDate.month}/${_selectedDate.day} ($weekday)';
      }
    }
  }

  String _getFullDateText() {
    return _formatDate(_selectedDate);
  }

  int _getCompletedCount() {
    return _dailyTodos.where((todo) => todo.isCompleted).length;
  }

  double _getCompletionRate() {
    if (_dailyTodos.isEmpty) return 0.0;
    return _getCompletedCount() / _dailyTodos.length;
  }

  Color _getProgressColor() {
    final rate = _getCompletionRate();
    if (rate == 1.0) return Colors.green;
    if (rate >= 0.7) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context);
    
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
                            localizations?.locale.languageCode == 'ko' ? '일일 습관 체크' :
                            localizations?.locale.languageCode == 'ja' ? '日次習慣チェック' : 'Daily Habit Check',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '오늘의 습관을 확인하고 체크하세요' :
                            localizations?.locale.languageCode == 'ja' ? '今日の習慣を確認してチェックしましょう' : 'Check and track your daily habits',
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
                        onPressed: _loadDailyData,
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
              
              // Date Selection & Progress
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  children: [
                    // Date Selector
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getDateDisplayText(context),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _getFullDateText(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Progress Section
                    if (_dailyTodos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      localizations?.locale.languageCode == 'ko' ? '완료: ${_getCompletedCount()}/${_dailyTodos.length}' :
                                      localizations?.locale.languageCode == 'ja' ? '完了: ${_getCompletedCount()}/${_dailyTodos.length}' : 'Completed: ${_getCompletedCount()}/${_dailyTodos.length}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getProgressColor().withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${(_getCompletionRate() * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _getProgressColor(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _getCompletionRate(),
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Todo List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _dailyTodos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    localizations?.locale.languageCode == 'ko' ? '이 날짜에는 할 일이 없습니다' :
                                    localizations?.locale.languageCode == 'ja' ? 'この日付にはタスクがありません' : 'No tasks for this date',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    localizations?.locale.languageCode == 'ko' ? '템플릿을 설정하고 새로고침을 눌러주세요' :
                                    localizations?.locale.languageCode == 'ja' ? 'テンプレートを設定してリフレッシュを押してください' : 'Set up templates and tap refresh',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _loadDailyData,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: Text(localizations?.locale.languageCode == 'ko' ? '새로고침' :
                                               localizations?.locale.languageCode == 'ja' ? 'リフレッシュ' : 'Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _dailyTodos.length,
                              itemBuilder: (context, index) {
                                final todo = _dailyTodos[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: todo.isCompleted 
                                        ? Colors.green.shade50 
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: todo.isCompleted 
                                          ? Colors.green.shade200 
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    value: todo.isCompleted,
                                    onChanged: (_) => _toggleTodoCompletion(index),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    activeColor: Colors.green.shade600,
                                    checkColor: Colors.white,
                                    title: Text(
                                      todo.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        decoration: todo.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: todo.isCompleted
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                      ),
                                    ),
                                    secondary: todo.isCompleted
                                        ? Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: Colors.green.shade600,
                                              size: 14,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 