import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import '../models/todo_item.dart';

class BackupService {
  static const String _backupFileName = 'habit_maker_backup.json';
  static const String _lastBackupKey = 'last_backup_date';
  static const String _appVersionKey = 'app_version';
  static const String _currentVersion = '1.0.0';

  // 자동 백업 (앱 시작시 실행)
  static Future<void> autoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getString(_lastBackupKey);
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // 하루에 한 번만 백업
      if (lastBackup != today) {
        await createBackup();
        await prefs.setString(_lastBackupKey, today);
        debugPrint('Auto backup completed: $today');
      }
    } catch (e) {
      debugPrint('Auto backup failed: $e');
    }
  }

  // 백업 생성
  static Future<String?> createBackup() async {
    try {
      final backupData = await _collectAllData();
      final backupJson = jsonEncode(backupData);
      
      // 내부 저장소에 백업 파일 저장
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/$_backupFileName');
      await backupFile.writeAsString(backupJson);
      
      // SharedPreferences에도 백업 저장 (이중 보안)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_data', backupJson);
      
      debugPrint('Backup created successfully: ${backupFile.path}');
      return backupFile.path;
    } catch (e) {
      debugPrint('Backup creation failed: $e');
      return null;
    }
  }

  // 모든 데이터 수집
  static Future<Map<String, dynamic>> _collectAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    final backupData = <String, dynamic>{
      'version': _currentVersion,
      'backup_date': DateTime.now().toIso8601String(),
      'data': <String, dynamic>{},
    };
    
    // 모든 SharedPreferences 데이터 수집
    for (final key in allKeys) {
      final value = prefs.get(key);
      if (value != null) {
        backupData['data'][key] = value;
      }
    }
    
    return backupData;
  }

  // 백업 복원
  static Future<bool> restoreBackup() async {
    try {
      String? backupJson;
      
      // 1. 파일에서 백업 읽기 시도
      try {
        final directory = await getApplicationDocumentsDirectory();
        final backupFile = File('${directory.path}/$_backupFileName');
        if (await backupFile.exists()) {
          backupJson = await backupFile.readAsString();
        }
      } catch (e) {
        debugPrint('File backup read failed: $e');
      }
      
      // 2. SharedPreferences에서 백업 읽기 시도
      if (backupJson == null) {
        final prefs = await SharedPreferences.getInstance();
        backupJson = prefs.getString('backup_data');
      }
      
      if (backupJson == null) {
        debugPrint('No backup data found');
        return false;
      }
      
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
      final data = backupData['data'] as Map<String, dynamic>;
      
      // 데이터 복원
      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
      
      debugPrint('Backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('Backup restoration failed: $e');
      return false;
    }
  }

  // 데이터 마이그레이션 (버전 업그레이드 시)
  static Future<void> migrateData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentAppVersion = prefs.getString(_appVersionKey);
      
      if (currentAppVersion != _currentVersion) {
        debugPrint('App version changed: $currentAppVersion -> $_currentVersion');
        
        // 버전별 마이그레이션 로직
        if (currentAppVersion == null) {
          // 첫 설치 또는 이전 버전에서 업그레이드
          await _migrateFromPreviousVersion();
        }
        
        // 현재 버전 저장
        await prefs.setString(_appVersionKey, _currentVersion);
        
        // 마이그레이션 후 백업 생성
        await createBackup();
      }
    } catch (e) {
      debugPrint('Data migration failed: $e');
    }
  }

  // 이전 버전에서 마이그레이션
  static Future<void> _migrateFromPreviousVersion() async {
    // 기존 데이터가 있는지 확인하고 필요시 복원
    final hasExistingData = await _hasExistingData();
    if (!hasExistingData) {
      // 백업에서 복원 시도
      await restoreBackup();
    }
  }

  // 기존 데이터 존재 여부 확인
  static Future<bool> _hasExistingData() async {
    final template = await StorageService.loadTemplate();
    return template.isNotEmpty;
  }

  // 백업 파일 존재 여부 확인
  static Future<bool> hasBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/$_backupFileName');
      return await backupFile.exists();
    } catch (e) {
      return false;
    }
  }

  // 백업 정보 가져오기
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/$_backupFileName');
      
      if (await backupFile.exists()) {
        final backupJson = await backupFile.readAsString();
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
        
        return {
          'version': backupData['version'],
          'backup_date': backupData['backup_date'],
          'file_size': await backupFile.length(),
        };
      }
    } catch (e) {
      debugPrint('Failed to get backup info: $e');
    }
    return null;
  }

  // 수동 백업 내보내기 (사용자가 직접 파일 저장)
  static Future<String?> exportBackup() async {
    try {
      final backupData = await _collectAllData();
      final backupJson = jsonEncode(backupData);
      
      // 외부 저장소에 백업 파일 생성
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final exportFile = File('${directory.path}/habit_maker_backup_$timestamp.json');
        await exportFile.writeAsString(backupJson);
        
        debugPrint('Backup exported: ${exportFile.path}');
        return exportFile.path;
      }
    } catch (e) {
      debugPrint('Backup export failed: $e');
    }
    return null;
  }
} 