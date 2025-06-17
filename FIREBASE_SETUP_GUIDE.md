# 🔥 Firebase 설정 가이드 (Android + iOS)

## 📋 개요
Firebase Console에서 Habit Maker 앱을 위한 Android 및 iOS 플랫폼 설정 방법을 안내합니다.

## 🤖 **Android 앱 설정** (기존 완료)

### 1단계: Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `habit-maker` (또는 원하는 이름)
4. Google Analytics 활성화 (권장)

### 2단계: Android 앱 추가
1. Firebase Console → 프로젝트 설정 → "앱 추가" → Android 선택
2. **앱 등록 정보**:
   - 패키지 이름: `com.habitmaker.app`
   - 앱 닉네임: `Habit Maker Android`
   - SHA-1 인증서 지문: (디버그용)
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```

### 3단계: google-services.json 다운로드 및 설정
1. Firebase Console에서 `google-services.json` 다운로드
2. 파일을 `android/app/` 폴더에 복사
3. 절대 Git에 커밋하지 마세요! (민감한 정보 포함)

## 🍎 **iOS 앱 설정** (새로 추가 필요)

### 1단계: iOS 앱 추가
1. Firebase Console → 동일한 프로젝트 → 프로젝트 설정 → "앱 추가" → iOS 선택
2. **앱 등록 정보**:
   - iOS 번들 ID: `com.habitmaker.app`
   - 앱 닉네임: `Habit Maker iOS`
   - App Store ID: (나중에 앱스토어 출시 후 추가)

### 2단계: GoogleService-Info.plist 다운로드
1. Firebase Console에서 `GoogleService-Info.plist` 다운로드
2. Xcode에서 `ios/Runner` 폴더에 추가:
   ```
   Xcode 열기 → ios/Runner.xcworkspace
   → Runner 프로젝트 선택 → Runner 타겟 선택
   → 우클릭 → "Add Files to Runner"
   → GoogleService-Info.plist 선택
   → "Copy items if needed" 체크
   → "Add to target: Runner" 체크
   ```

### 3단계: iOS Firebase SDK 추가
1. `ios/Podfile`이 이미 Firebase 의존성을 포함하고 있는지 확인:
   ```ruby
   # Firebase Crashlytics
   pod 'Firebase/Crashlytics'
   pod 'Firebase/Analytics'
   ```

2. 의존성 설치:
   ```bash
   cd ios
   pod install
   ```

### 4단계: iOS 앱에서 Firebase 초기화 코드 확인
`ios/Runner/AppDelegate.swift`에 Firebase 초기화가 있는지 확인:
```swift
import UIKit
import Flutter
import Firebase  // 추가

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()  // 추가
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 🔧 **공통 Firebase 서비스 설정**

### Crashlytics 설정 (양쪽 플랫폼 공통)
1. **자동 수집 활성화**: 이미 코드에 구현됨
2. **커스텀 로깅**: `FirebaseService.logMessage()` 사용
3. **오류 기록**: `FirebaseService.recordError()` 사용
4. **테스트 크래시**: 설정 화면에서 테스트 가능

### Analytics 설정 (양쪽 플랫폼 공통)
```dart
// 사용자 이벤트 추적 (필요시 추가)
await FirebaseAnalytics.instance.logEvent(
  name: 'habit_completed',
  parameters: {
    'habit_name': 'morning_exercise',
    'completion_time': DateTime.now().toString(),
  },
);
```

## 📁 **파일 구조 확인**

### Android
```
android/
├── app/
│   ├── google-services.json     ← Firebase 설정 파일
│   └── build.gradle            ← Firebase 플러그인 적용됨
└── build.gradle                ← Firebase 클래스패스 추가됨
```

### iOS
```
ios/
├── Runner/
│   ├── GoogleService-Info.plist  ← Firebase 설정 파일 (추가 필요)
│   └── AppDelegate.swift         ← Firebase 초기화 (확인 필요)
├── Podfile                       ← Firebase 의존성 (확인 필요)
└── Runner.xcworkspace            ← Xcode 작업공간
```

## ⚠️ **중요한 보안 주의사항**

### 🚫 **절대 Git에 포함하면 안되는 파일들**
```gitignore
# Android Firebase 설정
android/app/google-services.json

# iOS Firebase 설정  
ios/Runner/GoogleService-Info.plist

# 기타 민감한 정보
android/key.properties
ios/Runner/GoogleService-Info-Prod.plist
```

### 🔒 **안전한 관리 방법**
1. **템플릿 파일 생성**: 민감한 정보 제거한 템플릿 버전
2. **환경별 분리**: 개발/프로덕션 환경별 별도 Firebase 프로젝트
3. **팀 공유**: 안전한 채널로 실제 설정 파일 공유

## 🧪 **테스트 방법**

### Android 테스트
```bash
# 디버그 빌드로 테스트
flutter run --debug

# 릴리즈 빌드로 테스트  
flutter build apk --release
flutter install build/app/outputs/flutter-apk/app-release.apk
```

### iOS 테스트 (iOS 설정 완료 후)
```bash
# iOS 시뮬레이터에서 테스트
flutter run -d ios

# iOS 실제 기기에서 테스트 (개발자 계정 필요)
flutter run -d [기기ID] --release
```

### Firebase Console에서 확인
1. **Crashlytics**: 테스트 크래시가 정상적으로 수집되는지 확인
2. **Analytics**: 앱 실행 이벤트가 기록되는지 확인 
3. **사용자**: 활성 사용자 수가 표시되는지 확인

## 🚀 **다음 단계**

### iOS 앱 설정 완료 후 해야할 일
1. ✅ Firebase Console에서 iOS 앱 추가
2. ✅ GoogleService-Info.plist 다운로드 및 Xcode 프로젝트에 추가
3. ✅ iOS Firebase SDK 의존성 확인
4. ✅ AppDelegate.swift에 Firebase 초기화 코드 추가
5. ✅ iOS에서 실제 테스트 (크래시, 로깅 등)
6. ✅ App Store Connect 설정 (출시 시)

### 장기적 관리
- **정기적 SDK 업데이트**: Firebase 및 관련 패키지 최신 버전 유지
- **크래시 모니터링**: 주기적으로 Firebase Console 확인
- **성능 최적화**: Firebase Performance Monitoring 추가 고려
- **사용자 분석**: Firebase Analytics 데이터 활용

---

**💡 핵심: Android와 iOS 모두 동일한 Firebase 프로젝트에서 별도 앱으로 관리하여 통합 대시보드에서 모니터링!** 