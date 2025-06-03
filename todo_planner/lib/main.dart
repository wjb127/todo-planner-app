import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/template_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Google Mobile Ads 초기화
  await MobileAds.instance.initialize();
  
  // 알림 서비스 초기화
  await NotificationService.initialize();
  
  // 데이터 마이그레이션 및 백업 시스템 초기화
  await BackupService.migrateData();
  await BackupService.autoBackup();
  
  // 알림이 활성화되어 있다면 다시 스케줄링
  if (await NotificationService.isNotificationEnabled()) {
    await NotificationService.scheduleDailyNotification();
  }
  
  // 광고 서비스 초기화
  await AdService.initialize();
  
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
      locale: const Locale('en', 'US'), // 영어로 강제 설정
      
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
      home: const MainScreen(),
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
  bool _hasShownInitialAd = false;

  final List<Widget> _screens = [
    const TemplateScreen(),
    const DailyScreen(),
    const StatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 앱 시작 후 광고 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialAd();
    });
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

  Future<void> _showInitialAd() async {
    if (!_hasShownInitialAd) {
      print('🚀 앱 시작 - 초기 광고 표시 준비');
      await Future.delayed(const Duration(seconds: 2)); // 2초 후 광고 표시
      await AdService.showInterstitialAd();
      _hasShownInitialAd = true;
    }
  }

  Future<void> _showInterstitialAd() async {
    print('📊 통계 탭 이동 - 광고 표시');
    await AdService.showInterstitialAd();
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
            // 통계 탭으로 이동할 때 광고 표시
            if (_currentIndex != index && index == 2) {
              await _showInterstitialAd();
            }
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.view_list_rounded),
              label: 'Templates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.today_rounded),
              label: 'Daily',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Statistics',
            ),
          ],
        ),
      ),
    );
  }
}
