import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/todo_item.dart';
import '../services/storage_service.dart';

class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  List<TodoItem> _templateItems = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final template = await StorageService.loadTemplate();
    setState(() {
      _templateItems = template;
      _isLoading = false;
    });
  }

  Future<void> _saveTemplate() async {
    await StorageService.saveTemplate(_templateItems);
  }

  void _addHabit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _templateItems.add(TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
          isCompleted: false,
        ));
      });
      _textController.clear();
      _saveTemplate();
      _showSnackBar('Habit added successfully!');
    }
  }

  void _editHabit(int index) {
    _textController.text = _templateItems[index].title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Habit'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Enter habit name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _templateItems[index] = _templateItems[index].copyWith(title: text);
                });
                _saveTemplate();
                _showSnackBar('Habit updated successfully!');
              }
              _textController.clear();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteHabit(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${_templateItems[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _templateItems.removeAt(index);
              });
              _saveTemplate();
              _showSnackBar('Habit deleted successfully!');
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _templateItems.removeAt(oldIndex);
      _templateItems.insert(newIndex, item);
    });
    _saveTemplate();
    _showSnackBar('Order has been changed.');
  }

  Future<void> _applyTemplateFromToday() async {
    if (_templateItems.isEmpty) {
      _showSnackBar('Please add habits to the template first.', isError: true);
      return;
    }

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    bool todayApplied = false;
    bool todaySkipped = false;
    
    // 오늘 날짜 처리 - 진행 중이면 건너뛰기
    final todayTodos = await StorageService.loadDailyData(dateString);
    if (todayTodos.isNotEmpty && todayTodos.any((todo) => todo.isCompleted)) {
      todaySkipped = true;
    } else {
      // 오늘에 새 템플릿 적용
      final newTodos = _templateItems.map((templateItem) => TodoItem(
        id: '${templateItem.id}_$dateString',
        title: templateItem.title,
        isCompleted: false,
      )).toList();
      await StorageService.saveDailyData(dateString, newTodos);
      todayApplied = true;
    }
    
    // 내일부터 1개월 후까지 무조건 새 템플릿으로 적용
    final oneMonthLater = today.add(const Duration(days: 30));
    int futureDaysApplied = 0;
    
    for (DateTime date = tomorrow; 
         date.isBefore(oneMonthLater.add(const Duration(days: 1))); 
         date = date.add(const Duration(days: 1))) {
      
      final targetDateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // 템플릿을 기반으로 새로운 Todo 리스트 생성 (모든 항목 미완료 상태)
      final newTodos = _templateItems.map((templateItem) => TodoItem(
        id: '${templateItem.id}_$targetDateString',
        title: templateItem.title,
        isCompleted: false,
      )).toList();
      
      // 해당 날짜에 새로운 템플릿 저장 (기존 데이터 덮어쓰기)
      await StorageService.saveDailyData(targetDateString, newTodos);
      futureDaysApplied++;
    }
    
    // 템플릿 적용 날짜 저장
    await StorageService.saveTemplateAppliedDate(dateString);
    
    // 결과 메시지
    String message = '';
    if (todayApplied && futureDaysApplied > 0) {
      message = '✅ New habit template applied for ${futureDaysApplied + 1} days starting from today!';
    } else if (todaySkipped && futureDaysApplied > 0) {
      message = '✅ Today skipped, new habit template applied for ${futureDaysApplied} days starting tomorrow!';
    } else if (todayApplied && futureDaysApplied == 0) {
      message = '✅ New habit template applied for today only!';
    } else {
      message = 'There was a problem applying the template.';
    }
    
    _showSnackBar(message);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                      'Habit Templates',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create and manage your daily habit templates',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Add Todo Section
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Enter new habit',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addHabit(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addHabit,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${_templateItems.length}/30 habits',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (_templateItems.isNotEmpty) ...[
                          Icon(
                            Icons.drag_indicator_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Drag to reorder',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _templateItems.isEmpty
                      ? SingleChildScrollView(
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_task_rounded,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No habits in template',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first habit above',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _templateItems.length,
                          onReorder: _reorderItems,
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (BuildContext context, Widget? child) {
                                final double animValue = Curves.easeInOut.transform(animation.value);
                                final double elevation = lerpDouble(0, 6, animValue)!;
                                final double scale = lerpDouble(1, 1.02, animValue)!;
                                return Transform.scale(
                                  scale: scale,
                                  child: Material(
                                    elevation: elevation,
                                    borderRadius: BorderRadius.circular(12),
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            final item = _templateItems[index];
                            return Container(
                              key: ValueKey(item.id),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _editHabit(index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      // 순서 번호
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      
                                      // 할 일 텍스트
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      
                                      // 삭제 버튼과 드래그 핸들
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_rounded,
                                          color: Colors.red.shade600,
                                          size: 18,
                                        ),
                                        onPressed: () => _deleteHabit(index),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                      ),
                                      Icon(
                                        Icons.drag_handle_rounded,
                                        color: Colors.grey.shade400,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              
              // Apply Template Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: ElevatedButton.icon(
                  onPressed: _applyTemplateFromToday,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Apply Habit Template from Today'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
} 