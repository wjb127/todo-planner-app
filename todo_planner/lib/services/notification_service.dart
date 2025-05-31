import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _notificationEnabledKey = 'notification_enabled';
  
  // 다양한 후킹 멘트들
  static final List<String> _motivationalMessages = [
    '🌅 새로운 하루, 새로운 습관! 오늘도 성장해보세요',
    '💪 작은 습관이 큰 변화를 만듭니다. 시작해볼까요?',
    '⭐ 오늘의 습관 체크 시간이에요! 꾸준함이 힘입니다',
    '🎯 목표를 향한 한 걸음! 오늘 할 일을 확인해보세요',
    '🔥 습관의 힘을 믿어보세요. 오늘도 화이팅!',
    '🌱 매일 조금씩, 더 나은 나로 성장하고 있어요',
    '✨ 완벽하지 않아도 괜찮아요. 시작하는 것이 중요해요',
    '🚀 오늘도 습관 메이커가 되어보세요!',
    '💎 다이아몬드도 매일 갈아야 빛이 나요. 오늘도 갈아볼까요?',
    '🎨 오늘의 습관으로 인생이라는 캔버스를 채워보세요',
    '🏆 챔피언은 하루아침에 만들어지지 않아요. 오늘도 도전!',
    '🌟 별은 어둠 속에서 빛나듯, 꾸준함 속에서 성장해요'
  ];

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
    
    // 권한 요청
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      
      // Android 13+ 알림 권한
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 앱 내 특정 페이지로 이동하는 로직을 여기에 추가할 수 있습니다
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<void> scheduleDailyNotification() async {
    // 랜덤 메시지 선택
    final random = Random();
    final message = _motivationalMessages[random.nextInt(_motivationalMessages.length)];
    
    await _notifications.zonedSchedule(
      0, // 알림 ID
      '습관메이커', // 제목
      message, // 내용
      _nextInstanceOfEightAM(), // 다음 8시
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_habit_reminder',
          '일일 습관 알림',
          channelDescription: '매일 8시에 습관 체크를 알려드립니다',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );
    
    // 설정 저장
    await setNotificationEnabled(true);
  }

  static tz.TZDateTime _nextInstanceOfEightAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  static Future<void> cancelDailyNotification() async {
    await _notifications.cancel(0);
    await setNotificationEnabled(false);
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
} 