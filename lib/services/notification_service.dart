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
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
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

  // 권한 요청과 동시에 알림 스케줄링
  static Future<bool> requestPermissionsAndSchedule() async {
    debugPrint('🔔 권한 요청 및 알림 설정 시작');
    
    if (Platform.isAndroid) {
      // Android 13+ 알림 권한 요청
      final status = await Permission.notification.request();
      debugPrint('Notification permission status: $status');
      
      if (status.isGranted) {
        // 정확한 알람 권한도 요청 (Android 12+)
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        debugPrint('Exact alarm permission status: $alarmStatus');
        
        // 권한이 승인되면 즉시 알림 스케줄링
        await scheduleDailyNotification();
        debugPrint('✅ 권한 승인 후 알림 스케줄링 완료');
        return true;
      } else {
        debugPrint('❌ 알림 권한이 거부됨');
        return false;
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
      
      if (result == true) {
        // 권한이 승인되면 즉시 알림 스케줄링
        await scheduleDailyNotification();
        debugPrint('✅ iOS 권한 승인 후 알림 스케줄링 완료');
        return true;
      } else {
        debugPrint('❌ iOS 알림 권한이 거부됨');
        return false;
      }
    }
    
    return false;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
  }

  static void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    debugPrint('Local notification received: ID=$id, Title=$title, Body=$body, Payload=$payload');
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
    
    // 7시 알림 스케줄링 (아침 - 하루 시작)
    await _scheduleNotificationAt(7, 0, 0, 'morning');
    
    // 12시 알림 스케줄링 (점심 - 중간 체크)
    await _scheduleNotificationAt(12, 0, 1, 'afternoon');
    
    // 18시 알림 스케줄링 (저녁 - 하루 마무리)
    await _scheduleNotificationAt(18, 0, 2, 'evening');
    
    // 설정 저장
    await setNotificationEnabled(true);
    debugPrint('Daily notifications scheduled successfully (7:00 AM, 12:00 PM, 6:00 PM)');
  }

  static Future<void> _scheduleNotificationAt(int hour, int minute, int notificationId, String timeOfDay) async {
    final localizations = _getLocalizations();
    
    // 시간대별 메시지 선택
    List<String> messages;
    String title;
    
    switch (timeOfDay) {
      case 'morning':
        messages = [
          '🌅 새로운 하루가 시작되었어요! 오늘의 습관을 확인해보세요',
          '☕ 좋은 아침입니다! 하루를 습관으로 시작해보세요',
          '🚀 오늘도 성장하는 하루 만들어보시겠어요?',
          '💪 어제보다 더 나은 오늘을 위한 첫 걸음!',
          '🎯 오늘의 목표를 확인하고 시작해보세요',
          '✨ 작은 습관이 큰 변화를 만들어요',
          '🌱 성장하는 하루를 위한 습관 체크!'
        ];
        title = '🌅 ' + localizations.appTitle;
        break;
      case 'afternoon':
        messages = [
          '🌞 중간 체크 시간이에요! 오늘의 습관을 확인해보세요',
          '🍽️ 맛있는 점심을 즐겨보세요',
          '🎯 오늘의 목표를 확인하고 시작해보세요',
          '✨ 작은 습관이 큰 변화를 만들어요',
          '🌱 성장하는 하루를 위한 습관 체크!'
        ];
        title = '🌞 ' + localizations.appTitle;
        break;
      case 'evening':
        messages = [
          '🌙 하루 수고하셨어요! 오늘의 습관을 정리해보세요',
          '⭐ 오늘 하루는 어떠셨나요? 습관 체크로 마무리해요',
          '🎊 오늘도 한 걸음 더 성장했어요! 확인해보세요',
          '📝 하루를 되돌아보며 습관을 체크해보세요',
          '🏆 오늘의 성과를 확인하고 내일을 준비해요',
          '💝 스스로에게 주는 작은 선물, 습관 체크!',
          '🌟 끝까지 완주하신 오늘, 정말 대단해요!'
        ];
        title = '🌙 ' + localizations.appTitle;
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
        notificationId, // 알림 ID (7시: 0, 12시: 1, 18시: 2)
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
    await _notifications.cancel(0); // 7시 알림 취소
    await _notifications.cancel(1); // 12시 알림 취소
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

  // 즉시 테스트 알림 (강화된 버전 - 권한 체크 및 디버깅 포함)
  static Future<void> sendTestNotification() async {
    debugPrint('🔔 === 즉시 테스트 알림 시작 ===');
    
    try {
      // 1. iOS 권한 상태 확인
      if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          debugPrint('📱 iOS 알림 권한 재요청...');
          final result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('📱 권한 요청 결과: $result');
          
          if (result != true) {
            debugPrint('❌ 알림 권한이 거부되었습니다. 설정에서 알림을 활성화해주세요.');
            throw Exception('알림 권한이 필요합니다. 설정에서 알림을 활성화해주세요.');
          }
        }
      }
      
      // 2. 간단한 텍스트로 테스트
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      debugPrint('🚀 알림 전송 시도 - 시간: $timeString');
      
      await _notifications.show(
        999, // 테스트용 ID
        '🔔 테스트 알림',
        '알림이 정상 작동합니다! 시간: $timeString',
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'daily_habit_reminder',
            '일일 습관 알림',
            channelDescription: '즉시 테스트 알림',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            autoCancel: true,
            ongoing: false,
            showWhen: true,
            styleInformation: BigTextStyleInformation(
              '이것은 즉시 테스트 알림입니다. 알림이 정상적으로 작동하는지 확인하세요.',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            subtitle: '즉시 테스트',
          ),
        ),
      );
      
      debugPrint('✅ 즉시 테스트 알림 전송 완료!');
      debugPrint('💡 앱이 포그라운드에 있으면 알림이 보이지 않을 수 있습니다.');
      debugPrint('💡 홈 버튼을 누르거나 다른 앱으로 이동해보세요.');
      
    } catch (e, stackTrace) {
      debugPrint('❌ 즉시 테스트 알림 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
    
    debugPrint('🔔 === 즉시 테스트 알림 종료 ===');
  }

  // 매우 간단한 알림 테스트 (백업용)
  static Future<void> sendSimpleTestNotification() async {
    debugPrint('🔔 간단한 테스트 알림 전송...');
    
    try {
      await _notifications.show(
        888,
        'Simple Test',
        'This is a simple test notification',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Channel',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('✅ 간단한 테스트 알림 전송 완료');
    } catch (e) {
      debugPrint('❌ 간단한 테스트 알림 실패: $e');
      rethrow;
    }
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
      status['notification'] = notificationStatus.toString();
      status['exactAlarm'] = alarmStatus.toString();
    } else if (Platform.isIOS) {
      status['notification'] = 'iOS - Check in Settings';
    }
    
    return status;
  }

  // 모든 예약된 알림 목록 가져오기
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // 30초 뒤 테스트 알림 (개발/테스트용)
  static Future<void> scheduleTestNotificationAfter30Seconds() async {
    final localizations = _getLocalizations();
    final userTimezone = _getUserTimezone();
    final now = tz.TZDateTime.now(userTimezone);
    final scheduledTime = now.add(const Duration(seconds: 30));
    
    debugPrint('🔔 30초 후 테스트 알림 예약');
    debugPrint('현재 시간: $now');
    debugPrint('알림 예정 시간: $scheduledTime');
    debugPrint('30초 후: ${scheduledTime.difference(now).inSeconds}초');
    
    // 권한 체크
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        debugPrint('❌ 알림 권한이 없습니다. 권한을 요청합니다.');
        await _requestPermissions();
        return;
      }
    }
    
    try {
      await _notifications.zonedSchedule(
        1000, // 테스트용 ID (다른 알림과 겹치지 않게)
        '🔔 테스트 알림 - 30초 후',
        '알림이 정상적으로 작동하고 있습니다! 현재 시간: ${DateTime.now().toString().substring(11, 19)}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_habit_reminder',
            '일일 습관 알림',
            channelDescription: '30초 후 테스트 알림',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
            autoCancel: true,
            ongoing: false,
            styleInformation: BigTextStyleInformation(
              '이 알림은 테스트용입니다. 앱이 백그라운드에 있어도 알림이 정상적으로 전달되는지 확인하세요.',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            subtitle: '30초 후 테스트 알림',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('✅ 30초 후 테스트 알림 예약 완료!');
      debugPrint('💡 이제 앱을 백그라운드로 보내서 알림이 오는지 확인해보세요.');
      
    } catch (e) {
      debugPrint('❌ 30초 후 알림 예약 실패: $e');
      rethrow;
    }
  }

  // 5초 뒤 즉시 테스트 알림 (빠른 테스트용)
  static Future<void> scheduleTestNotificationAfter5Seconds() async {
    final localizations = _getLocalizations();
    final userTimezone = _getUserTimezone();
    final now = tz.TZDateTime.now(userTimezone);
    final scheduledTime = now.add(const Duration(seconds: 5));
    
    debugPrint('🔔 5초 후 즉시 테스트 알림 예약');
    debugPrint('현재 시간: $now');
    debugPrint('알림 예정 시간: $scheduledTime');
    
    try {
      await _notifications.zonedSchedule(
        1001, // 테스트용 ID
        '⚡ 즉시 테스트 - 5초 후',
        '빠른 테스트 알림입니다! ${DateTime.now().toString().substring(11, 19)}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_habit_reminder',
            '일일 습관 알림',
            channelDescription: '5초 후 즉시 테스트 알림',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            showWhen: true,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            subtitle: '5초 후 즉시 테스트',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('✅ 5초 후 즉시 테스트 알림 예약 완료!');
      
    } catch (e) {
      debugPrint('❌ 5초 후 알림 예약 실패: $e');
      rethrow;
    }
  }

  // 테스트 알림들 취소
  static Future<void> cancelTestNotifications() async {
    await _notifications.cancel(1000); // 30초 후 테스트 알림
    await _notifications.cancel(1001); // 5초 후 테스트 알림
    debugPrint('🚫 모든 테스트 알림이 취소되었습니다.');
  }

  // 포그라운드에서 즉시 다이얼로그로 보여주는 알림
  static Future<void> showForegroundTestDialog(BuildContext context) async {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    debugPrint('🔔 포그라운드 다이얼로그 알림 표시');
    
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('🔔 테스트 알림'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '포그라운드 알림 테스트입니다!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '현재 시간: $timeString',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '💡 iOS에서는 앱이 포그라운드에 있을 때 즉시 알림이 표시되지 않습니다. 대신 이런 다이얼로그나 백그라운드 알림을 테스트해보세요!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      );
    }
  }
} 