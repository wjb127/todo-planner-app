import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_item.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class StorageService {
  static const String _templateKey = 'todo_template';
  static const String _dailyDataKey = 'daily_data';
  static const String _templateAppliedDateKey = 'template_applied_date';

  // 템플릿 저장/불러오기
  static Future<void> saveTemplate(List<TodoItem> template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templateJson = jsonEncode(template.map((item) => item.toJson()).toList());
      await prefs.setString(_templateKey, templateJson);
      
      print('✅ 템플릿 저장 성공: ${template.length}개 항목');
      
    } catch (e, stackTrace) {
      // Firebase Crashlytics에 오류 기록
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'saveTemplate 메서드에서 템플릿 저장 실패',
        fatal: false,
      );
      
      print('❌ 템플릿 저장 실패: $e');
      rethrow; // 상위 코드에서 처리할 수 있도록 다시 던짐
    }
  }

  static Future<List<TodoItem>> loadTemplate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templateJson = prefs.getString(_templateKey);
      
      if (templateJson == null) {
        print('📝 템플릿이 없어서 빈 리스트 반환');
        return [];
      }
      
      final List<dynamic> templateList = jsonDecode(templateJson);
      final template = templateList.map((json) => TodoItem.fromJson(json)).toList();
      
      print('✅ 템플릿 로드 성공: ${template.length}개 항목');
      return template;
      
    } catch (e, stackTrace) {
      // Firebase Crashlytics에 오류 기록
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'loadTemplate 메서드에서 템플릿 로드 실패',
        fatal: false,
      );
      
      print('❌ 템플릿 로드 실패: $e');
      return []; // 실패 시 빈 리스트 반환
    }
  }

  // 일일 데이터 저장/불러오기 (날짜별)
  static Future<void> saveDailyData(String date, List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = todos.map((item) => item.toJson()).toList();
    await prefs.setString('$_dailyDataKey$date', jsonEncode(jsonList));
  }

  static Future<List<TodoItem>> loadDailyData(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_dailyDataKey$date');
    if (jsonString == null) {
      // 해당 날짜에 데이터가 없으면 템플릿을 복사해서 반환
      final template = await loadTemplate();
      return template.map((item) => TodoItem(
        id: item.id,
        title: item.title,
        isCompleted: false,
      )).toList();
    }
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => TodoItem.fromJson(json)).toList();
  }

  // 템플릿 적용 날짜 저장/불러오기
  static Future<void> saveTemplateAppliedDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templateAppliedDateKey, date);
  }

  static Future<String?> getTemplateAppliedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_templateAppliedDateKey);
  }

  // 특정 기간의 모든 일일 데이터 키 가져오기
  static Future<List<String>> getAllDailyDataKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    return allKeys.where((key) => key.startsWith(_dailyDataKey)).toList();
  }

  // 오래된 데이터 정리 (6개월 이전 데이터 삭제)
  static Future<void> cleanOldData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    
    final allKeys = await getAllDailyDataKeys();
    for (final key in allKeys) {
      final dateString = key.replaceFirst(_dailyDataKey, '');
      try {
        final date = DateTime.parse(dateString);
        if (date.isBefore(sixMonthsAgo)) {
          await prefs.remove(key);
        }
      } catch (e) {
        // 잘못된 날짜 형식의 키는 삭제
        await prefs.remove(key);
      }
    }
  }

  // 기존 패키지명에서 데이터 마이그레이션 (선택사항)
  static Future<void> migrateFromOldPackage() async {
    final prefs = await SharedPreferences.getInstance();
    final hasMigrated = prefs.getBool('has_migrated_data') ?? false;
    
    if (!hasMigrated) {
      // 마이그레이션 완료 표시
      await prefs.setBool('has_migrated_data', true);
      
      // 여기에 기존 데이터 복구 로직을 추가할 수 있습니다
      // 하지만 패키지명이 다르면 접근이 어렵습니다
      debugPrint('Data migration check completed');
    }
  }
} 