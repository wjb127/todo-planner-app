import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static FirebaseCrashlytics? _crashlytics;
  static FirebaseAnalytics? _analytics;

  /// Firebase 초기화
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('🔥 Firebase 이미 초기화됨');
      return;
    }

    try {
      // Firebase 초기화
      await Firebase.initializeApp();
      print('🔥 Firebase 초기화 완료');

      // Crashlytics 설정
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Analytics 초기화
      _analytics = FirebaseAnalytics.instance;
      
      // 자동 크래시 수집 활성화 (릴리즈 모드에서만)
      if (!kDebugMode) {
        await _crashlytics?.setCrashlyticsCollectionEnabled(true);
        print('🔥 Firebase Crashlytics 자동 수집 활성화됨');
      } else {
        await _crashlytics?.setCrashlyticsCollectionEnabled(false);
        print('🔍 Debug 모드: Crashlytics 수집 비활성화됨');
      }
      
      // Analytics 자동 수집 활성화
      await _analytics?.setAnalyticsCollectionEnabled(true);
      print('📊 Firebase Analytics 초기화 완료');
      
      _isInitialized = true;
      print('✅ Firebase Service 초기화 완료');
    } catch (e) {
      print('❌ Firebase 초기화 실패: $e');
      _isInitialized = true; // 실패해도 초기화 완료로 표시
    }
  }

  /// 사용자 정보 설정
  static Future<void> setUserId(String userId) async {
    try {
      await _crashlytics?.setUserIdentifier(userId);
      await _analytics?.setUserId(id: userId);
      print('👤 사용자 ID 설정: $userId');
    } catch (e) {
      print('❌ 사용자 ID 설정 실패: $e');
    }
  }

  /// 커스텀 키-값 설정
  static Future<void> setCustomKey(String key, String value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
      await _analytics?.setUserProperty(name: key, value: value);
      print('🔑 커스텀 키 설정: $key = $value');
    } catch (e) {
      print('❌ 커스텀 키 설정 실패: $e');
    }
  }

  /// 비치명적 오류 기록
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      print('⚠️ Firebase 오류 기록: $exception');
    } catch (e) {
      print('❌ Firebase 오류 기록 실패: $e');
    }
  }

  /// 커스텀 로그 기록
  static Future<void> logMessage(String message) async {
    try {
      await _crashlytics?.log(message);
      print('📝 Firebase 로그: $message');
    } catch (e) {
      print('❌ Firebase 로깅 실패: $e');
    }
  }

  /// 테스트 크래시 (릴리즈 모드에서만)
  static Future<void> testCrash() async {
    if (!kDebugMode) {
      _crashlytics?.crash();
    } else {
      print('🔍 Debug 모드에서는 크래시 테스트를 실행하지 않습니다');
    }
  }

  /// 초기화 상태 확인
  static bool get isInitialized => _isInitialized;

  // === 📊 Google Analytics 이벤트 추적 기능들 ===

  // 앱 시작 이벤트
  static Future<void> logAppStart() async {
    try {
      await _analytics?.logAppOpen();
      print('🚀 앱 시작 이벤트 기록됨');
    } catch (e) {
      print('❌ 앱 시작 이벤트 기록 실패: $e');
    }
  }

  // 습관 생성 이벤트
  static Future<void> logHabitCreated(String habitName) async {
    try {
      await _analytics?.logEvent(
        name: 'habit_created',
        parameters: {
          'habit_name': habitName,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      print('✅ 습관 생성 이벤트: $habitName');
    } catch (e) {
      print('❌ 습관 생성 이벤트 기록 실패: $e');
    }
  }

  // 습관 완료 이벤트
  static Future<void> logHabitCompleted(String habitName) async {
    try {
      await _analytics?.logEvent(
        name: 'habit_completed',
        parameters: {
          'habit_name': habitName,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
      print('🎯 습관 완료 이벤트: $habitName');
    } catch (e) {
      print('❌ 습관 완료 이벤트 기록 실패: $e');
    }
  }

  // 화면 조회 이벤트
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
      );
      print('📺 화면 조회 이벤트: $screenName');
    } catch (e) {
      print('❌ 화면 조회 이벤트 기록 실패: $e');
    }
  }

  // 설정 변경 이벤트
  static Future<void> logSettingChanged(String settingName, String value) async {
    try {
      await _analytics?.logEvent(
        name: 'setting_changed',
        parameters: {
          'setting_name': settingName,
          'new_value': value,
          'changed_at': DateTime.now().toIso8601String(),
        },
      );
      print('⚙️ 설정 변경 이벤트: $settingName = $value');
    } catch (e) {
      print('❌ 설정 변경 이벤트 기록 실패: $e');
    }
  }

  // 광고 클릭 이벤트
  static Future<void> logAdClicked(String adType) async {
    try {
      await _analytics?.logEvent(
        name: 'ad_clicked',
        parameters: {
          'ad_type': adType,
          'clicked_at': DateTime.now().toIso8601String(),
        },
      );
      print('📱 광고 클릭 이벤트: $adType');
    } catch (e) {
      print('❌ 광고 클릭 이벤트 기록 실패: $e');
    }
  }

  // 사용자 정의 이벤트
  static Future<void> logCustomEvent(
    String eventName,
    Map<String, Object> parameters,
  ) async {
    try {
      await _analytics?.logEvent(
        name: eventName,
        parameters: parameters,
      );
      print('🎯 커스텀 이벤트: $eventName');
    } catch (e) {
      print('❌ 커스텀 이벤트 기록 실패: $e');
    }
  }
} 