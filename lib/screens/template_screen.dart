import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/todo_item.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../l10n/app_localizations.dart';

class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  List<TodoItem> _templateItems = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;
  int _addHabitCount = 0; // 습관 추가 횟수 카운터
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _textController.dispose();
    _bannerAd?.dispose();
    super.dispose();
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

  Future<void> _addHabit() async {
    final localizations = AppLocalizations.of(context);
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _templateItems.add(TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
          isCompleted: false,
        ));
        _addHabitCount++; // 카운터 증가
      });
      _textController.clear();
      _saveTemplate();
      _showSnackBar(localizations?.locale.languageCode == 'ko' ? '습관이 추가되었습니다!' :
                   localizations?.locale.languageCode == 'ja' ? '習慣が追加されました！' : 'Habit added successfully!');
      
      // 3번째, 6번째, 9번째... 습관 추가 시 광고 표시
      if (_addHabitCount % 3 == 0) {
        print('🎯 습관 추가 ${_addHabitCount}회 - 광고 표시');
        await _showAdAfterDelay();
      }
    }
  }

  Future<void> _showAdAfterDelay() async {
    // 1초 후 광고 표시 (사용자 경험을 위해)
    await Future.delayed(const Duration(seconds: 1));
    try {
      await AdService.showInterstitialAd();
    } catch (e) {
      print('❌ 습관 추가 후 광고 표시 실패: $e');
    }
  }

  void _editHabit(int index) {
    final localizations = AppLocalizations.of(context);
    _textController.text = _templateItems[index].title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.locale.languageCode == 'ko' ? '습관 수정' :
                   localizations?.locale.languageCode == 'ja' ? '習慣編集' : 'Edit Habit'),
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: localizations?.locale.languageCode == 'ko' ? '습관을 입력하세요' :
                     localizations?.locale.languageCode == 'ja' ? '習慣を入力してください' : 'Enter habit name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.locale.languageCode == 'ko' ? '취소' :
                        localizations?.locale.languageCode == 'ja' ? 'キャンセル' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _templateItems[index] = _templateItems[index].copyWith(title: text);
                });
                _saveTemplate();
                _showSnackBar(localizations?.locale.languageCode == 'ko' ? '습관이 수정되었습니다!' :
                             localizations?.locale.languageCode == 'ja' ? '習慣が編集されました！' : 'Habit updated successfully!');
              }
              _textController.clear();
              Navigator.pop(context);
            },
            child: Text(localizations?.locale.languageCode == 'ko' ? '저장' :
                        localizations?.locale.languageCode == 'ja' ? '保存' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteHabit(int index) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.locale.languageCode == 'ko' ? '습관 삭제' :
                   localizations?.locale.languageCode == 'ja' ? '習慣削除' : 'Delete Habit'),
        content: Text(localizations?.locale.languageCode == 'ko' ? '"${_templateItems[index].title}"을(를) 삭제하시겠습니까?' :
                     localizations?.locale.languageCode == 'ja' ? '"${_templateItems[index].title}"を削除しますか？' : 'Are you sure you want to delete "${_templateItems[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.locale.languageCode == 'ko' ? '취소' :
                        localizations?.locale.languageCode == 'ja' ? 'キャンセル' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _templateItems.removeAt(index);
              });
              _saveTemplate();
              _showSnackBar(localizations?.locale.languageCode == 'ko' ? '습관이 삭제되었습니다!' :
                           localizations?.locale.languageCode == 'ja' ? '習慣が削除されました！' : 'Habit deleted successfully!');
              Navigator.pop(context);
            },
            child: Text(localizations?.locale.languageCode == 'ko' ? '삭제' :
                        localizations?.locale.languageCode == 'ja' ? '削除' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _reorderItems(int oldIndex, int newIndex) {
    final localizations = AppLocalizations.of(context);
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _templateItems.removeAt(oldIndex);
      _templateItems.insert(newIndex, item);
    });
    _saveTemplate();
    _showSnackBar(localizations?.locale.languageCode == 'ko' ? '순서가 변경되었습니다.' :
                 localizations?.locale.languageCode == 'ja' ? '順序が変更されました。' : 'Order has been changed.');
  }

  Future<void> _applyTemplateFromToday() async {
    final localizations = AppLocalizations.of(context);
    if (_templateItems.isEmpty) {
      _showSnackBar(localizations?.locale.languageCode == 'ko' ? '템플릿에 습관을 먼저 추가해주세요.' :
                   localizations?.locale.languageCode == 'ja' ? 'テンプレートに習慣を先に追加してください。' : 'Please add habits to the template first.', isError: true);
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
      message = localizations?.locale.languageCode == 'ko' ? '✅ 오늘부터 ${futureDaysApplied + 1}일간 새로운 습관 템플릿이 적용되었습니다!' :
                localizations?.locale.languageCode == 'ja' ? '✅ 今日から${futureDaysApplied + 1}日間、新しい習慣テンプレートが適用されました！' : '✅ New habit template applied for ${futureDaysApplied + 1} days starting from today!';
    } else if (todaySkipped && futureDaysApplied > 0) {
      message = localizations?.locale.languageCode == 'ko' ? '✅ 오늘은 건너뛰고 내일부터 ${futureDaysApplied}일간 새로운 습관 템플릿이 적용되었습니다!' :
                localizations?.locale.languageCode == 'ja' ? '✅ 今日はスキップして明日から${futureDaysApplied}日間、新しい習慣テンプレートが適用されました！' : '✅ Today skipped, new habit template applied for ${futureDaysApplied} days starting tomorrow!';
    } else if (todayApplied && futureDaysApplied == 0) {
      message = localizations?.locale.languageCode == 'ko' ? '✅ 오늘에만 새로운 습관 템플릿이 적용되었습니다!' :
                localizations?.locale.languageCode == 'ja' ? '✅ 今日のみ新しい習慣テンプレートが適用されました！' : '✅ New habit template applied for today only!';
    } else {
      message = localizations?.locale.languageCode == 'ko' ? '템플릿 적용에 문제가 발생했습니다.' :
                localizations?.locale.languageCode == 'ja' ? 'テンプレート適用に問題が発生しました。' : 'There was a problem applying the template.';
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
          duration: const Duration(seconds: 1), // 1초로 변경
        ),
      );
    }
  }

  Future<void> _loadBannerAd() async {
    // 광고 제거 구매 여부 확인
    final adRemoved = await AdService.isAdRemoved();
    if (adRemoved) {
      print('💰 광고 제거됨: 배너광고 로드 건너뜀');
      return;
    }

    try {
      _bannerAd = AdService.createBannerAd();
      await _bannerAd!.load();
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
        print('✅ 템플릿 화면 배너광고 로드 성공');
      }
    } catch (e) {
      print('❌ 템플릿 화면 배너광고 로드 실패: $e');
      _bannerAd?.dispose();
      _bannerAd = null;
      _isAdLoaded = false;
      
      // 10초 후 재시도
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && !_isAdLoaded) {
          _loadBannerAd();
        }
      });
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

    final localizations = AppLocalizations.of(context);

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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 
                          MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
              // Header - 미려한 디자인으로 개선
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '습관 템플릿' :
                            localizations?.locale.languageCode == 'ja' ? '習慣テンプレート' : 'Habit Template',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '매일 실천할 루틴을 만들어보세요' :
                            localizations?.locale.languageCode == 'ja' ? '毎日実践するルーチンを作ってみましょう' : 'Build your daily routine',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8), // 간격 더 줄임
              
              // Add Todo Section - 미려한 디자인으로 개선
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
                            decoration: InputDecoration(
                              hintText: localizations?.locale.languageCode == 'ko' ? '새로운 습관 추가' :
                                       localizations?.locale.languageCode == 'ja' ? '新しい習慣を追加' : 'Enter new habit',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8), // 패딩 줄임
                            ),
                            onSubmitted: (_) => _addHabit(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _addHabit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      localizations?.locale.languageCode == 'ko' ? '추가' :
                                      localizations?.locale.languageCode == 'ja' ? '追加' : 'Add',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // 12 → 8로 줄임
                    Row(
                      children: [
                        Text(
                          localizations?.locale.languageCode == 'ko' ? '${_templateItems.length}/30개' :
                          localizations?.locale.languageCode == 'ja' ? '${_templateItems.length}/30個' : '${_templateItems.length}/30 habits',
                          style: TextStyle(
                            fontSize: 13, // 14 → 13으로 줄임
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (_templateItems.isNotEmpty) ...[
                          Icon(
                            Icons.drag_indicator_rounded,
                            size: 14, // 16 → 14로 줄임
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localizations?.locale.languageCode == 'ko' ? '드래그하여 순서 변경' :
                            localizations?.locale.languageCode == 'ja' ? 'ドラッグして순序変更' : 'Drag to reorder',
                            style: TextStyle(
                              fontSize: 11, // 12 → 11로 줄임
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8), // 간격 더 줄임
              
              // Todo List - 미려한 디자인으로 개선
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                constraints: BoxConstraints(
                  minHeight: 150,
                  maxHeight: MediaQuery.of(context).size.height * 0.35, // 최대 높이 제한
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _templateItems.isEmpty
                    ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_task_rounded,
                                    size: 48, // 64 → 48로 줄임
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12), // 16 → 12로 줄임
                                  Text(
                                    localizations?.locale.languageCode == 'ko' ? '템플릿에 습관을 추가해보세요!' :
                                    localizations?.locale.languageCode == 'ja' ? 'テンプレートに習慣を追加してみましょう！' : 'No habits in template',
                                    style: TextStyle(
                                      fontSize: 16, // 18 → 16으로 줄임
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6), // 8 → 6으로 줄임
                                  Text(
                                    localizations?.locale.languageCode == 'ko' ? '매일 반복할 루틴을 만들어보세요' :
                                    localizations?.locale.languageCode == 'ja' ? '毎日繰り返すルーチンを作ってみましょう' : 'Add your first habit above',
                                    style: TextStyle(
                                      fontSize: 13, // 14 → 13으로 줄임
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                    : ReorderableListView.builder(
                          padding: const EdgeInsets.all(16),
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
              
              // 버튼과 리스트 사이 간격
              const SizedBox(height: 16),
              
              // Apply Template Button - 기존 스타일로 복구
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // 패딩 조정
                child: ElevatedButton.icon(
                  onPressed: _applyTemplateFromToday,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(localizations?.locale.languageCode == 'ko' ? '오늘부터 습관 템플릿 적용하기' :
                              localizations?.locale.languageCode == 'ja' ? '今日から習慣テンプレートを適용' : 'Apply Habit Template from Today'),
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
              
              // 키보드 여백 추가
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 