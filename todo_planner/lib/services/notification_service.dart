import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _notificationEnabledKey = 'notification_enabled';
  
  // 지원하는 국가별 시간대 매핑
  static const Map<String, String> _countryTimezones = {
    'KR': 'Asia/Seoul',        // 한국
    'JP': 'Asia/Tokyo',        // 일본
    'US': 'America/New_York',  // 미국 동부
    'CA': 'America/Toronto',   // 캐나다
    'GB': 'Europe/London',     // 영국
    'DE': 'Europe/Berlin',     // 독일
    'FR': 'Europe/Paris',      // 프랑스
    'AU': 'Australia/Sydney',  // 호주
    'CN': 'Asia/Shanghai',     // 중국
    'IN': 'Asia/Kolkata',      // 인도
  };

  static Future<void> initialize() async {
    // 타임존 초기화
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Android 알림 채널 생성
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_habit_reminder',
        '일일 습관 알림',
        description: '매일 정해진 시간에 습관 체크를 알려드립니다',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
      );
      
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.createNotificationChannel(channel);
      debugPrint('Notification channel created: ${channel.id}');
    }
    
    // 권한 요청
    await _requestPermissions();
  }

  // 사용자의 현재 시간대 자동 감지
  static tz.Location _getUserTimezone() {
    try {
      // 1. 시스템 로케일에서 국가 코드 추출 시도
      final locale = Platform.localeName; // 예: "ko_KR", "en_US", "ja_JP"
      debugPrint('System locale: $locale');
      
      if (locale.contains('_')) {
        final countryCode = locale.split('_').last.toUpperCase();
        debugPrint('Detected country code: $countryCode');
        
        if (_countryTimezones.containsKey(countryCode)) {
          final timezoneName = _countryTimezones[countryCode]!;
          debugPrint('Using timezone: $timezoneName');
          return tz.getLocation(timezoneName);
        }
      }
      
      // 2. 시스템 시간대 사용 (fallback)
      debugPrint('Using system local timezone');
      return tz.local;
    } catch (e) {
      debugPrint('Error detecting timezone: $e, using UTC');
      return tz.UTC;
    }
  }

  // 현재 로케일 감지
  static String _getCurrentLanguageCode() {
    try {
      final locale = Platform.localeName;
      if (locale.contains('_')) {
        return locale.split('_').first.toLowerCase();
      }
      return locale.toLowerCase();
    } catch (e) {
      return 'en'; // 기본값
    }
  }

  // 로케일에 맞는 AppLocalizations 생성
  static AppLocalizations _getLocalizations() {
    final languageCode = _getCurrentLanguageCode();
    final supportedLanguages = ['ko', 'ja', 'en'];
    
    final locale = supportedLanguages.contains(languageCode) 
        ? Locale(languageCode) 
        : const Locale('en');
    
    return AppLocalizations(locale);
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ 알림 권한 요청
      final status = await Permission.notification.request();
      debugPrint('Notification permission status: $status');
      
      if (status.isDenied) {
        debugPrint('Notification permission denied, requesting again...');
        await Permission.notification.request();
      }
      
      // 정확한 알람 권한도 요청 (Android 12+)
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      debugPrint('Exact alarm permission status: $alarmStatus');
      
      // 배터리 최적화 예외 요청
      try {
        final batteryOptimizationStatus = await Permission.ignoreBatteryOptimizations.request();
        debugPrint('Battery optimization permission status: $batteryOptimizationStatus');
      } catch (e) {
        debugPrint('Battery optimization permission request failed: $e');
      }
      
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      debugPrint('iOS notification permission result: $result');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<void> scheduleDailyNotification() async {
    // 권한 체크
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        debugPrint('Notification permission not granted, requesting...');
        await _requestPermissions();
      }
    }
    
    // 기존 알림 모두 취소
    await _notifications.cancelAll();
    debugPrint('Cancelled all existing notifications');
    
    // 8시 알림 스케줄링 (아침)
    await _scheduleNotificationAt(8, 0, 0, 'morning');
    
    // 13시 알림 스케줄링 (오후)
    await _scheduleNotificationAt(13, 0, 1, 'afternoon');
    
    // 18시 알림 스케줄링 (저녁)
    await _scheduleNotificationAt(18, 0, 2, 'evening');
    
    // 설정 저장
    await setNotificationEnabled(true);
    debugPrint('Daily notifications scheduled successfully (8:00 AM, 1:00 PM, 6:00 PM)');
  }

  static Future<void> _scheduleNotificationAt(int hour, int minute, int notificationId, String timeOfDay) async {
    final localizations = _getLocalizations();
    
    // 시간대별 메시지 선택
    List<String> messages;
    String title;
    
    switch (timeOfDay) {
      case 'morning':
        messages = localizations.morningMessages;
        title = localizations.appTitle + ' (Morning)';
        break;
      case 'afternoon':
        messages = localizations.afternoonMessages;
        title = localizations.appTitle + ' (Afternoon)';
        break;
      case 'evening':
        messages = localizations.eveningMessages;
        title = localizations.appTitle + ' (Evening)';
        break;
      default:
        messages = localizations.motivationalMessages;
        title = localizations.appTitle;
    }
    
    // 랜덤 메시지 선택
    final random = Random();
    final message = messages[random.nextInt(messages.length)];
    
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    debugPrint('=== NOTIFICATION SCHEDULING DEBUG ===');
    final userTimezone = _getUserTimezone();
    final now = tz.TZDateTime.now(userTimezone);
    debugPrint('User timezone: ${userTimezone.name}');
    debugPrint('Current time (${userTimezone.name}): $now');
    debugPrint('Scheduling $title notification for: $scheduledTime');
    debugPrint('Time difference: ${scheduledTime.difference(now).inMinutes} minutes from now');
    debugPrint('Notification ID: $notificationId');
    debugPrint('Notification message: $message');
    
    // 권한 상태 확인
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      debugPrint('Notification permission: $notificationStatus');
      debugPrint('Exact alarm permission: $alarmStatus');
    }
    
    try {
      await _notifications.zonedSchedule(
        notificationId, // 알림 ID (8시: 0, 13시: 1, 18시: 2)
        title, // 제목
        message, // 내용
        scheduledTime, // 지정된 시간
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_habit_reminder',
            '일일 습관 알림',
            channelDescription: '매일 정해진 시간에 습관 체크를 알려드립니다',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
            autoCancel: false,
            ongoing: false,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
      );
      debugPrint('✅ Notification scheduled successfully!');
      
      // 스케줄된 알림 목록 확인
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      debugPrint('Pending notifications count: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        debugPrint('Pending: ID=${notification.id}, Title=${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
    debugPrint('=== END DEBUG ===');
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final userTimezone = _getUserTimezone();
    final tz.TZDateTime now = tz.TZDateTime.now(userTimezone);
    tz.TZDateTime scheduledDate = tz.TZDateTime(userTimezone, now.year, now.month, now.day, hour, minute);
    
    // 현재 시간보다 이전이면 다음 날로 설정
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    debugPrint('Next instance calculation:');
    debugPrint('  Current time: $now');
    debugPrint('  Target time today: ${tz.TZDateTime(userTimezone, now.year, now.month, now.day, hour, minute)}');
    debugPrint('  Final scheduled time: $scheduledDate');
    
    return scheduledDate;
  }

  static Future<void> cancelDailyNotification() async {
    await _notifications.cancel(0); // 8시 알림 취소
    await _notifications.cancel(1); // 13시 알림 취소
    await _notifications.cancel(2); // 18시 알림 취소
    await setNotificationEnabled(false);
    debugPrint('All daily notifications cancelled');
  }

  static Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? false;
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
  }

  static Future<void> toggleNotification() async {
    final isEnabled = await isNotificationEnabled();
    
    if (isEnabled) {
      await cancelDailyNotification();
    } else {
      await scheduleDailyNotification();
    }
  }

  // 즉시 테스트 알림 (출시용 - 간단한 테스트만)
  static Future<void> sendTestNotification() async {
    final localizations = _getLocalizations();
    final random = Random();
    final message = localizations.motivationalMessages[random.nextInt(localizations.motivationalMessages.length)];
    
    await _notifications.show(
      999, // 테스트용 ID
      localizations.appTitle + ' (Test)',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_habit_reminder',
          '일일 습관 알림',
          channelDescription: '알림 테스트용',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
    );
    debugPrint('Test notification sent: $message');
  }

  // 현재 설정된 시간대 정보 가져오기 (디버그용)
  static String getCurrentTimezoneInfo() {
    final userTimezone = _getUserTimezone();
    final now = tz.TZDateTime.now(userTimezone);
    return 'Timezone: ${userTimezone.name}, Current time: $now';
  }

  // 알림 권한 상태 확인
  static Future<Map<String, String>> getPermissionStatus() async {
    final Map<String, String> status = {};
    
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      
      status['notification'] = notificationStatus.toString();
      status['exactAlarm'] = alarmStatus.toString();
      status['batteryOptimization'] = batteryStatus.toString();
    } else if (Platform.isIOS) {
      status['notification'] = 'iOS - Check in Settings';
    }
    
    return status;
  }

  // 모든 예약된 알림 목록 가져오기
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
} 