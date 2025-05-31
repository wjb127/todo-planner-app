import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../services/storage_service.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  DateTime _selectedDate = DateTime.now();
  List<TodoItem> _dailyTodos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
    StorageService.cleanOldData(); // 앱 시작시 오래된 데이터 정리
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
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyData();
    }
  }

  String _getDateDisplayText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    if (selected == today) {
      return '오늘 (${_formatDate(_selectedDate)})';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return '어제 (${_formatDate(_selectedDate)})';
    } else if (selected == today.add(const Duration(days: 1))) {
      return '내일 (${_formatDate(_selectedDate)})';
    } else {
      return _formatDate(_selectedDate);
    }
  }

  int _getCompletedCount() {
    return _dailyTodos.where((todo) => todo.isCompleted).length;
  }

  double _getCompletionRate() {
    if (_dailyTodos.isEmpty) return 0.0;
    return _getCompletedCount() / _dailyTodos.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일일 체크'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 날짜 선택 영역
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getDateDisplayText(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 진행률 표시
                if (_dailyTodos.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '완료: ${_getCompletedCount()}/${_dailyTodos.length}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${(_getCompletionRate() * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _getCompletionRate(),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCompletionRate() == 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          // Todo 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _dailyTodos.isEmpty
                    ? const Center(
                        child: Text(
                          '이 날짜에는 할 일이 없습니다.\n템플릿을 먼저 설정해주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _dailyTodos.length,
                        itemBuilder: (context, index) {
                          final todo = _dailyTodos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: todo.isCompleted
                                      ? Colors.grey
                                      : null,
                                ),
                              ),
                              value: todo.isCompleted,
                              onChanged: (_) => _toggleTodoCompletion(index),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 