import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ko', 'KR'), // 한국어
    Locale('ja', 'JP'), // 일본어
    Locale('en', 'US'), // 영어 (미국)
  ];

  // 앱 제목
  String get appTitle {
    switch (locale.languageCode) {
      case 'ko':
        return '습관메이커';
      case 'ja':
        return 'ハビットメーカー';
      case 'en':
      default:
        return 'Habit Maker';
    }
  }

  // 알림 메시지들
  List<String> get motivationalMessages {
    switch (locale.languageCode) {
      case 'ko':
        return [
          '🌅 새로운 하루, 새로운 습관! 오늘도 성장해보세요',
          '💪 작은 습관이 큰 변화를 만듭니다. 시작해볼까요?',
          '⭐ 오늘의 습관 체크 시간이에요! 꾸준함이 힘입니다',
          '🎯 목표를 향한 한 걸음! 오늘 할 일을 확인해보세요',
          '🔥 습관의 힘을 믿어보세요. 오늘도 화이팅!',
          '🌱 매일 조금씩, 더 나은 나로 성장하고 있어요',
          '✨ 완벽하지 않아도 괜찮아요. 시작하는 것이 중요해요',
          '🚀 오늘도 습관 메이커가 되어보세요!',
        ];
      case 'ja':
        return [
          '🌅 新しい一日、新しい習慣！今日も成長しましょう',
          '💪 小さな習慣が大きな変化を作ります。始めてみませんか？',
          '⭐ 今日の習慣チェック時間です！継続は力なり',
          '🎯 目標への一歩！今日やることを確認しましょう',
          '🔥 習慣の力を信じてください。今日もファイト！',
          '🌱 毎日少しずつ、より良い自分に成長しています',
          '✨ 完璧でなくても大丈夫。始めることが大切です',
          '🚀 今日もハビットメーカーになりましょう！',
        ];
      case 'en':
      default:
        return [
          '🌅 New day, new habits! Let\'s grow today',
          '💪 Small habits create big changes. Shall we start?',
          '⭐ Time for today\'s habit check! Consistency is key',
          '🎯 A step towards your goal! Check what to do today',
          '🔥 Believe in the power of habits. Fighting today too!',
          '🌱 Growing into a better you, little by little every day',
          '✨ It\'s okay not to be perfect. Starting is what matters',
          '🚀 Let\'s be a habit maker today too!',
        ];
    }
  }

  // 시간대별 메시지
  List<String> get morningMessages {
    switch (locale.languageCode) {
      case 'ko':
        return [
          '🌅 좋은 아침! 오늘의 습관을 시작해보세요',
          '☀️ 새로운 하루가 시작됐어요. 습관 체크!',
          '🌞 아침 습관으로 하루를 활기차게 시작하세요',
          '⭐ 아침 8시, 습관 메이커 시간입니다!',
        ];
      case 'ja':
        return [
          '🌅 おはようございます！今日の習慣を始めましょう',
          '☀️ 新しい一日が始まりました。習慣チェック！',
          '🌞 朝の習慣で一日を活気よく始めましょう',
          '⭐ 朝8時、ハビットメーカータイムです！',
        ];
      case 'en':
      default:
        return [
          '🌅 Good morning! Let\'s start today\'s habits',
          '☀️ A new day has begun. Habit check!',
          '🌞 Start your day energetically with morning habits',
          '⭐ 8 AM, it\'s Habit Maker time!',
        ];
    }
  }

  List<String> get afternoonMessages {
    switch (locale.languageCode) {
      case 'ko':
        return [
          '🍽️ 점심시간! 오전 습관은 어떠셨나요?',
          '☀️ 하루의 중간 지점! 지금까지 잘하고 계세요',
          '🌞 점심 후 오후 습관도 체크해보세요!',
          '⚡ 에너지 충전 시간! 습관 체크도 잊지 마세요',
        ];
      case 'ja':
        return [
          '🍽️ お昼の時間！午前の習慣はいかがでしたか？',
          '☀️ 一日の中間地点！ここまでよく頑張っています',
          '🌞 昼食後、午後の習慣もチェックしましょう！',
          '⚡ エネルギー充電時間！習慣チェックもお忘れなく',
        ];
      case 'en':
      default:
        return [
          '🍽️ Lunch time! How were your morning habits?',
          '☀️ Midpoint of the day! You\'re doing great so far',
          '🌞 After lunch, check your afternoon habits too!',
          '⚡ Energy recharge time! Don\'t forget habit check',
        ];
    }
  }

  List<String> get eveningMessages {
    switch (locale.languageCode) {
      case 'ko':
        return [
          '🌆 저녁 시간! 오늘 하루 습관은 어떠셨나요?',
          '🌙 하루를 마무리하며 습관을 점검해보세요',
          '✨ 저녁 습관으로 하루를 완성하세요',
          '🎯 오늘의 마지막 습관 체크 시간입니다!',
        ];
      case 'ja':
        return [
          '🌆 夕方の時間！今日一日の習慣はいかがでしたか？',
          '🌙 一日を締めくくりながら習慣をチェックしましょう',
          '✨ 夕方の習慣で一日を完成させましょう',
          '🎯 今日最後の習慣チェック時間です！',
        ];
      case 'en':
      default:
        return [
          '🌆 Evening time! How were your habits today?',
          '🌙 Check your habits as you wrap up the day',
          '✨ Complete your day with evening habits',
          '🎯 Time for today\'s final habit check!',
        ];
    }
  }

  // 설정 화면 텍스트들
  String get settings => locale.languageCode == 'ko' ? '설정' : 
                        locale.languageCode == 'ja' ? '設定' : 'Settings';
  
  String get notificationSettings => locale.languageCode == 'ko' ? '알림 설정' : 
                                   locale.languageCode == 'ja' ? '通知設定' : 'Notification Settings';
  
  String get dailyHabitReminder => locale.languageCode == 'ko' ? '매일 습관 알림 (8시, 13시, 18시)' : 
                                 locale.languageCode == 'ja' ? '毎日の習慣リマインダー (8時、13時、18時)' : 'Daily Habit Reminder (8AM, 1PM, 6PM)';
  
  String get notificationDescription => locale.languageCode == 'ko' ? '매일 오전 8시, 오후 1시, 오후 6시에 습관 체크를 알려드려요' : 
                                      locale.languageCode == 'ja' ? '毎日午前8時、午後1時、午後6時に習慣チェックをお知らせします' : 'We\'ll remind you to check your habits at 8AM, 1PM, and 6PM every day';
  
  String get notificationEnabled => locale.languageCode == 'ko' ? '알림이 활성화되었습니다. 매일 8시, 13시, 18시에 다양한 동기부여 메시지를 받아보세요!' : 
                                  locale.languageCode == 'ja' ? '通知が有効になりました。毎日8時、13時、18時に様々なモチベーションメッセージを受け取りましょう！' : 'Notifications are enabled. Receive various motivational messages at 8AM, 1PM, and 6PM every day!';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((supportedLocale) => 
        supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 