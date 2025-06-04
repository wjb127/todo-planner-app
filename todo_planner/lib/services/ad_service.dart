import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AdService {
  static const String _adRemovedKey = 'ad_removed';
  static const String _testModeKey = 'test_mode';
  
  // 출시용: 테스트 모드 기본값을 false로 설정
  static bool _isTestMode = false;
  static bool _isInitialized = false;
  
  // 실제 광고 ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2803803669720807/1723563018'; // Android 전면광고 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2803803669720807/2186381844'; // iOS 전면광고 ID
    }
    throw UnsupportedError('Unsupported platform');
  }
  
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2803803669720807/6300978111'; // Android 배너광고 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2803803669720807/2934735716'; // iOS 배너광고 ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;
  static bool _isLoadingAd = false;

  // 애드몹 초기화
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('🔥 AdService 이미 초기화됨');
      return;
    }

    try {
      // Google Mobile Ads 초기화
      print('🔄 Google Mobile Ads 초기화 중...');
      await MobileAds.instance.initialize();
      
      // iOS에서 App Tracking Transparency 권한 요청
      if (Platform.isIOS) {
        await _requestTrackingPermission();
      }
      
      _isTestMode = await getTestMode();
      _isInitialized = true;
      
      print('🔥 AdService initialized - Test mode: $_isTestMode');
      
      // 첫 번째 광고 미리 로드
      _loadInterstitialAd();
      
    } catch (e) {
      print('❌ AdService 초기화 실패: $e');
      _isInitialized = true; // 실패해도 초기화 완료로 표시
    }
  }

  // App Tracking Transparency 권한 요청 (iOS 전용)
  static Future<void> _requestTrackingPermission() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      print('📱 현재 추적 권한 상태: $status');
      
      // 아직 권한을 요청하지 않았다면 요청
      if (status == TrackingStatus.notDetermined) {
        print('🔔 추적 권한 요청 중...');
        final result = await AppTrackingTransparency.requestTrackingAuthorization();
        print('✅ 추적 권한 요청 결과: $result');
      }
    } catch (e) {
      print('❌ 추적 권한 요청 실패: $e');
    }
  }

  // 전면 광고 로드
  static void _loadInterstitialAd() {
    // 이미 로딩 중이거나 테스트 모드에서는 로드하지 않음
    if (_isLoadingAd || _isInterstitialAdReady || _isTestMode) {
      if (_isTestMode) print('🧪 테스트 모드: 광고 로드 건너뜀');
      if (_isLoadingAd) print('⏳ 이미 광고 로딩 중');
      if (_isInterstitialAdReady) print('✅ 광고 이미 준비됨');
      return;
    }
    
    _isLoadingAd = true;
    print('📱 전면광고 로드 시작... ID: $interstitialAdUnitId');
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _isLoadingAd = false;
          print('✅ 전면광고 로드 완료');
          
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('📱 광고 닫힘');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // 다음 광고 미리 로드
              Future.delayed(const Duration(seconds: 1), () {
                _loadInterstitialAd();
              });
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ 광고 표시 실패: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ 전면광고 로드 실패: $error');
          _isInterstitialAdReady = false;
          _isLoadingAd = false;
          
          // 에러 코드에 따른 재시도 로직
          if (error.code == 0) { // Too many requests
            // 10초 후 재시도
            Future.delayed(const Duration(seconds: 10), () {
              _loadInterstitialAd();
            });
          } else {
            // 5초 후 재시도
            Future.delayed(const Duration(seconds: 5), () {
              _loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  // 전면 광고 표시
  static Future<void> showInterstitialAd() async {
    print('🎯 광고 표시 요청 - 테스트모드: $_isTestMode, 광고준비: $_isInterstitialAdReady');
    
    // 테스트 모드에서는 광고 표시하지 않음
    if (_isTestMode) {
      print('🧪 테스트 모드: 광고 표시 건너뜀');
      return;
    }
    
    final adRemoved = await isAdRemoved();
    if (adRemoved) {
      print('💰 광고 제거됨: 광고 표시 건너뜀');
      return;
    }
    
    if (_isInterstitialAdReady && _interstitialAd != null) {
      print('🚀 전면광고 표시!');
      await _interstitialAd!.show();
    } else {
      print('⏳ 광고가 아직 준비되지 않음 - 다시 로드 시도');
      // 광고가 준비되지 않았다면 다시 로드 시도
      _loadInterstitialAd();
    }
  }

  // 광고 준비 상태 확인
  static bool get isAdReady => _isInterstitialAdReady;
  
  // 초기화 상태 확인
  static bool get isInitialized => _isInitialized;

  // 광고 제거 상태 확인
  static Future<bool> isAdRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adRemovedKey) ?? false;
  }

  // 광고 제거 설정
  static Future<void> setAdRemoved(bool removed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adRemovedKey, removed);
  }

  // 테스트 모드 상태 확인 (출시용: 기본값 false)
  static Future<bool> getTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testModeKey) ?? false; // 기본값 false
  }

  // 테스트 모드 설정
  static Future<void> setTestMode(bool testMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, testMode);
    _isTestMode = testMode;
    
    print('🔧 테스트 모드 변경: $testMode');
    
    if (testMode) {
      // 테스트 모드 활성화 시 기존 광고 정리
      dispose();
    } else {
      // 테스트 모드 비활성화 시 광고 다시 로드
      _loadInterstitialAd();
    }
  }

  // 현재 테스트 모드 상태
  static bool get isTestMode => _isTestMode;

  // 리소스 정리
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    _isLoadingAd = false;
  }
} 