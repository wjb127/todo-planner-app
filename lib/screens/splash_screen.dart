import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
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
  
  bool _loadingComplete = false;
  String _statusMessage = 'Loading...';

  @override
  void initState() {
    super.initState();
    
    // 상태바 숨기기
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
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
    
    setState(() {
      _statusMessage = 'Initializing...';
    });
    
    // 최소 2초는 대기 (사용자 경험)
    await Future.delayed(const Duration(seconds: 2));
    
    // AdService 초기화 확인 및 광고 준비 대기
    try {
      setState(() {
        _statusMessage = 'Preparing ads...';
      });
      
      // AdService가 초기화되었는지 확인
      if (!AdService.isInitialized) {
        print('🔄 AdService 초기화되지 않음 - 초기화 시도');
        await AdService.initialize();
      }
      
      // 테스트 모드가 아니고 광고가 제거되지 않았다면 광고 준비 대기
      if (!await AdService.getTestMode() && !await AdService.isAdRemoved()) {
        // 최대 5초까지 광고 준비 대기
        int waitCount = 0;
        while (!AdService.isInterstitialAdReady && waitCount < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          waitCount++;
          if (waitCount == 5) {
            setState(() {
              _statusMessage = 'Loading ads...';
            });
          }
        }
        
        if (AdService.isInterstitialAdReady) {
          print('✅ 광고 준비 완료');
        } else {
          print('⏰ 광고 준비 시간 초과 - 계속 진행');
        }
      } else {
        print('🧪 테스트 모드 또는 광고 제거됨 - 광고 준비 건너뜀');
      }
      
    } catch (e) {
      print('❌ 광고 초기화 실패: $e');
    }
    
    setState(() {
      _statusMessage = 'Ready!';
      _loadingComplete = true;
    });
    
    // 추가 0.5초 대기 후 메인 화면으로 이동
    await Future.delayed(const Duration(milliseconds: 500));
    _navigateToMain();
  }

  void _navigateToMain() async {
    if (_loadingComplete) {
      // 상태바 복원
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      
      // 스플래시 이후 광고 표시 시도
      bool adShown = false;
      try {
        print('🚀 앱 시작 - 초기 광고 표시 준비');
        
        // 광고가 준비되었다면 표시
        if (AdService.isInterstitialAdReady) {
          print('🎯 초기 광고 표시 시도');
          await AdService.showInterstitialAd();
          adShown = true;
          print('✅ 초기 광고 표시 완료');
        } else {
          print('⏳ 광고가 아직 준비되지 않음 - 메인 화면으로 이동');
        }
      } catch (e) {
        print('❌ 스플래시 광고 표시 실패: $e');
      }
      
      // 광고가 표시되지 않았다면 약간의 지연 후 메인 화면으로 이동
      if (!adShown) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 안전한 방법으로 다국어 처리
    final localizations = Localizations.maybeLocaleOf(context)?.languageCode == 'ko'
        ? '습관메이커'
        : 'Habit Maker';
    
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
                                localizations,
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
                                Localizations.maybeLocaleOf(context)?.languageCode == 'ko' 
                                  ? '매일 반복하는 작은 변화, 큰 성장의 시작'
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