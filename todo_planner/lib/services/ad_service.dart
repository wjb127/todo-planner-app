import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static const String _adRemovedKey = 'ad_removed';
  static const String _testModeKey = 'test_mode';
  
  // 테스트 모드 설정 (개발 중에는 true로 설정)
  static bool _isTestMode = false;
  
  // 실제 광고 ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2803803669720807/1723563018'; // 실제 전면광고 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2803803669720807/1723563018'; // iOS용 전면광고 ID (동일하게 사용)
    }
    throw UnsupportedError('Unsupported platform');
  }
  
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2803803669720807/6300978111'; // 배너광고 ID (필요시 별도 생성)
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2803803669720807/2934735716'; // iOS 배너광고 ID (필요시 별도 생성)
    }
    throw UnsupportedError('Unsupported platform');
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  // 애드몹 초기화
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _isTestMode = await getTestMode();
    _loadInterstitialAd();
  }

  // 전면 광고 로드
  static void _loadInterstitialAd() {
    // 테스트 모드에서는 광고 로드하지 않음
    if (_isTestMode) return;
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // 다음 광고 미리 로드
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // 전면 광고 표시
  static Future<void> showInterstitialAd() async {
    // 테스트 모드에서는 광고 표시하지 않음
    if (_isTestMode) {
      print('🧪 테스트 모드: 광고 표시 건너뜀');
      return;
    }
    
    final adRemoved = await isAdRemoved();
    if (adRemoved) return;
    
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    }
  }

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

  // 테스트 모드 상태 확인
  static Future<bool> getTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testModeKey) ?? false;
  }

  // 테스트 모드 설정
  static Future<void> setTestMode(bool testMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, testMode);
    _isTestMode = testMode;
    
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
  }
} 