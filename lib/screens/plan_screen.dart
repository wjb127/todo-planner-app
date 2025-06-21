import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/todo_item.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../l10n/app_localizations.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with AutomaticKeepAliveClientMixin {
  
  // 외부에서 새로고침을 호출할 수 있는 공개 메서드
  void refresh() {
    _loadPlanData();
  }
  
  DateTime _selectedDate = DateTime.now();
  List<TodoItem> _planTodos = [];
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPlanData();
    _loadBannerAd();
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

  Future<void> _loadPlanData() async {
    setState(() {
      _isLoading = true;
    });

    final dateString = _formatDate(_selectedDate);
    final plans = await StorageService.loadPlanData(dateString);
    
    setState(() {
      _planTodos = plans;
      _isLoading = false;
    });
  }

  Future<void> _savePlanData() async {
    final dateString = _formatDate(_selectedDate);
    await StorageService.savePlanData(dateString, _planTodos);
  }

  void _toggleTodoCompletion(int index) {
    setState(() {
      _planTodos[index] = _planTodos[index].copyWith(
        isCompleted: !_planTodos[index].isCompleted,
      );
    });
    _savePlanData();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final oneYearLater = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: oneYearAgo,
      lastDate: oneYearLater,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadPlanData();
    }
  }

  String _getDateDisplayText(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    if (selected == today) {
      return localizations?.locale.languageCode == 'ko' ? '오늘' : 'Today';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return localizations?.locale.languageCode == 'ko' ? '어제' : 'Yesterday';
    } else if (selected == today.add(const Duration(days: 1))) {
      return localizations?.locale.languageCode == 'ko' ? '내일' : 'Tomorrow';
    } else {
      return '${_selectedDate.month}/${_selectedDate.day}';
    }
  }

  String _getFullDateText() {
    return _formatDate(_selectedDate);
  }

  int _getCompletedCount() {
    return _planTodos.where((todo) => todo.isCompleted).length;
  }

  double _getCompletionRate() {
    if (_planTodos.isEmpty) return 0.0;
    return _getCompletedCount() / _planTodos.length;
  }

  Color _getProgressColor() {
    final rate = _getCompletionRate();
    if (rate == 1.0) return Colors.green;
    if (rate >= 0.7) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Future<void> _showAddPlanDialog() async {
    String planText = '';
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(
            localizations?.locale.languageCode == 'ko' ? '새 계획 추가' : 'Add New Plan',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: localizations?.locale.languageCode == 'ko' ? '계획을 입력하세요' : 'Enter your plan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              planText = value;
            },
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                localizations?.locale.languageCode == 'ko' ? '취소' : 'Cancel',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(
                localizations?.locale.languageCode == 'ko' ? '추가' : 'Add',
              ),
              onPressed: () {
                if (planText.trim().isNotEmpty) {
                  setState(() {
                    _planTodos.add(TodoItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: planText.trim(),
                      isCompleted: false,
                    ));
                  });
                  _savePlanData();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deletePlan(int index) {
    setState(() {
      _planTodos.removeAt(index);
    });
    _savePlanData();
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
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '일일 계획' : 'Daily Plan',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '오늘의 계획을 세우고 실행하세요' : 'Plan your day and execute it',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Date Selection
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Previous day button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          });
                          _loadPlanData();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Date display (clickable)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  _getDateDisplayText(context),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getFullDateText(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    // Next day button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                          _loadPlanData();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
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
                      ? const Center(child: CircularProgressIndicator())
                      : _planTodos.isEmpty
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
                                    localizations?.locale.languageCode == 'ko' ? '이 날짜에는 계획이 없습니다' : 'No plans for this date',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    localizations?.locale.languageCode == 'ko' ? '+ 버튼을 눌러 계획을 추가해주세요' : 'Tap + button to add plans',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom: _isAdLoaded ? 80 : 16, // 배너광고를 위한 하단 패딩
                              ),
                              itemCount: _planTodos.length,
                              itemBuilder: (context, index) {
                                final todo = _planTodos[index];
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
                                    secondary: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (todo.isCompleted)
                                          Container(
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
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () => _deletePlan(index),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.shade400,
                                            size: 18,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlanDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 