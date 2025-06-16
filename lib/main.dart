import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/template_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // 안전한 Flutter 바인딩 초기화 with 오류 처리
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('🔍 Flutter 바인딩 초기화 완료');
  } catch (e) {
    print('❌ Flutter 바인딩 초기화 실패: $e');
    // 바인딩 실패 시에도 앱 실행 계속
  }
  
  // 안전한 서비스 초기화 with 오류 처리
  try {
    print('🔔 알림 서비스 초기화 시작');
    await NotificationService.initialize();
    print('🔔 알림 서비스 초기화 완료');
  } catch (e) {
    print('❌ 알림 서비스 초기화 실패: $e');
  }
  
  try {
    print('💾 백업 서비스 초기화 시작');
    await BackupService.migrateData();
    await BackupService.autoBackup();
    print('💾 백업 서비스 초기화 완료');
  } catch (e) {
    print('❌ 백업 서비스 초기화 실패: $e');
  }
  
  try {
    // 알림이 활성화되어 있다면 다시 스케줄링
    if (await NotificationService.isNotificationEnabled()) {
      await NotificationService.scheduleDailyNotification();
      print('🔔 알림 스케줄링 완료');
    }
  } catch (e) {
    print('❌ 알림 스케줄링 실패: $e');
  }
  
  // AdService 초기화 (중요!)
  try {
    print('📱 광고 서비스 초기화 시작');
    await AdService.initialize();
    print('📱 광고 서비스 초기화 완료');
  } catch (e) {
    print('❌ 광고 서비스 초기화 실패: $e');
  }
  
  // PurchaseService 초기화
  try {
    print('💰 인앱결제 서비스 초기화 시작');
    await PurchaseService.initialize();
    print('💰 인앱결제 서비스 초기화 완료');
  } catch (e) {
    print('❌ 인앱결제 서비스 초기화 실패: $e');
  }
  
  print('🚀 앱 실행 시작');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Maker',
      debugShowCheckedModeBanner: false,
      
      // 다국어 지원 설정
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // 각 페이지의 새로고침을 제어하기 위한 GlobalKey
  final GlobalKey _dailyKey = GlobalKey();
  final GlobalKey _statisticsKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 화면 리스트 초기화 (GlobalKey 포함)
    _screens = [
      const TemplateScreen(),
      DailyScreen(key: _dailyKey),
      StatisticsScreen(key: _statisticsKey),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdService.dispose();
    PurchaseService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }



  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.appTitle ?? 'Habit Maker'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) async {
            // 같은 탭을 다시 눌렀을 때 새로고침
            if (_currentIndex == index) {
              if (index == 1) {
                // 일일 페이지 새로고침
                (_dailyKey.currentState as dynamic)?.refresh();
              } else if (index == 2) {
                // 통계 페이지 새로고침
                (_statisticsKey.currentState as dynamic)?.refresh();
              }
              return;
            }
            

            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.view_list_rounded),
              label: localizations?.templatesTab ?? 'Templates',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.today_rounded),
              label: localizations?.dailyTab ?? 'Daily',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.analytics_rounded),
              label: localizations?.statisticsTab ?? 'Statistics',
            ),
          ],
        ),
      ),
    );
  }
}
