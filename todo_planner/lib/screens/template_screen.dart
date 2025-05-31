import 'package:flutter/material.dart';
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('템플릿이 저장되었습니다.')),
      );
    }
  }

  void _addTodoItem() {
    if (_textController.text.trim().isEmpty) return;
    if (_templateItems.length >= 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 30개까지만 추가할 수 있습니다.')),
      );
      return;
    }

    setState(() {
      _templateItems.add(TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _textController.text.trim(),
      ));
    });
    _textController.clear();
    _saveTemplate();
  }

  void _removeTodoItem(int index) {
    setState(() {
      _templateItems.removeAt(index);
    });
    _saveTemplate();
  }

  void _editTodoItem(int index, String newTitle) {
    setState(() {
      _templateItems[index] = _templateItems[index].copyWith(title: newTitle);
    });
    _saveTemplate();
  }

  Future<void> _applyTemplateFromToday() async {
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await StorageService.saveTemplateAppliedDate(dateString);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘부터 새로운 템플릿이 적용됩니다.')),
      );
    }
  }

  void _showEditDialog(int index) {
    final controller = TextEditingController(text: _templateItems[index].title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '할 일을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _editTodoItem(index, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo 템플릿'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _applyTemplateFromToday,
            icon: const Icon(Icons.play_arrow),
            tooltip: '오늘부터 현재 템플릿 반영',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '새로운 할 일을 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTodoItem(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTodoItem,
                  child: const Text('추가'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${_templateItems.length}/30개',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: _templateItems.isEmpty
                ? const Center(
                    child: Text(
                      '템플릿에 할 일을 추가해보세요!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _templateItems.length,
                    itemBuilder: (context, index) {
                      final item = _templateItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(item.title),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeTodoItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
} 