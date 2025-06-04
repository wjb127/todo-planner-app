import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ad_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _adLoadingComplete = false;
  bool _minimumTimeComplete = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    
    // 상태바 숨기기
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // 초기 상태 메시지 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _statusMessage = AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ko' 
            ? '로딩 중...'
            : AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ja'
              ? '読み込み中...'
              : 'Loading...';
        });
      }
    });
    
    // 애니메이션 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    ));
    
    // 초기화 시작
    _initialize();
  }

  Future<void> _initialize() async {
    // 애니메이션 시작
    _animationController.forward();
    
    // 병렬로 실행
    await Future.wait([
      _loadAds(),
      _waitMinimumTime(),
    ]);
    
    // 모든 로딩이 완료되면 메인 화면으로 이동
    _navigateToMain();
  }

  Future<void> _loadAds() async {
    try {
      setState(() {
        _statusMessage = AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ko' 
          ? '광고 시스템 초기화 중...'
          : AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ja'
            ? '広告システム初期化中...'
            : 'Initializing ad system...';
      });
      
      // 애드몹 초기화
      await AdService.initialize();
      
      setState(() {
        _statusMessage = AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ko' 
          ? '완료!'
          : AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ja'
            ? '完了！'
            : 'Complete!';
        _adLoadingComplete = true;
      });
      
      print('🚀 스플래시: 애드몹 초기화 완료');
    } catch (e) {
      print('❌ 스플래시: 애드몹 초기화 실패 - $e');
      setState(() {
        _statusMessage = AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ko' 
          ? '준비 완료!'
          : AppLocalizations(Localizations.localeOf(context)).locale.languageCode == 'ja'
            ? '準備完了！'
            : 'Ready!';
        _adLoadingComplete = true;
      });
    }
  }

  Future<void> _waitMinimumTime() async {
    // 최소 2초 대기 (사용자 경험을 위해)
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _minimumTimeComplete = true;
    });
  }

  void _navigateToMain() async {
    if (_adLoadingComplete && _minimumTimeComplete) {
      // 상태바 복원
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      
      // 스플래시 이후 전면광고 표시 시도
      await _showStartupAd();
      
      // 메인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    }
  }

  Future<void> _showStartupAd() async {
    try {
      print('🎯 스플래시: 시작 광고 표시 시도');
      await AdService.showInterstitialAd();
    } catch (e) {
      print('❌ 스플래시: 시작 광고 표시 실패 - $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(Localizations.localeOf(context));
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 앱 아이콘/로고
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // 앱 이름
                              Text(
                                localizations.appTitle,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // 슬로건
                              Text(
                                localizations.locale.languageCode == 'ko' 
                                  ? '매일 반복하는 작은 변화, 큰 성장의 시작'
                                  : localizations.locale.languageCode == 'ja'
                                    ? '毎日の小さな変化が、大きな成長の始まり'
                                    : 'Small daily changes, the beginning of great growth',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // 하단 로딩 영역
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    // 로딩 인디케이터
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 상태 메시지
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessage,
                        key: ValueKey(_statusMessage),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 