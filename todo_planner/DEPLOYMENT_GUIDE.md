# 습관메이커 배포 가이드

## 📱 인앱결제 설정

### 1. Google Play Console 설정 (Android)

#### 1-1. 앱 등록
1. [Google Play Console](https://play.google.com/console) 접속
2. "앱 만들기" → 앱 정보 입력
3. 앱 번들 업로드 (aab 파일)

#### 1-2. 인앱 상품 생성
```
경로: 앱 선택 → 수익 창출 → 인앱 상품
1. "상품 만들기" 클릭
2. 상품 ID: remove_ads_11000 (중요: 코드와 정확히 일치해야 함)
3. 이름: 광고 제거
4. 설명: 광고 없는 깔끔한 환경에서 습관을 관리하세요
5. 가격: ₩11,000
6. 상품 유형: 관리형 상품 (일회성 구매)
7. 상태: 활성
```

#### 1-3. 테스트 계정 설정
```
경로: 설정 → 라이선스 테스트
1. 테스트 계정 Gmail 추가
2. 라이선스 응답: LICENSED
```

### 2. App Store Connect 설정 (iOS)

#### 2-1. 앱 등록
1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. "내 앱" → "+" → "새로운 앱"
3. 앱 정보 입력

#### 2-2. 인앱 구입 생성
```
경로: 앱 선택 → 기능 → 인앱 구입
1. "+" 버튼 클릭
2. 유형: 비소모성 (Non-Consumable)
3. 참조 이름: 광고 제거
4. 제품 ID: remove_ads_11000 (중요: Android와 동일해야 함)
5. 가격: ₩11,000 (Tier 선택)
6. 현지화된 정보 추가
```

#### 2-3. 샌드박스 테스터 설정
```
경로: 사용자 및 액세스 → 샌드박스 테스터
1. "+" 버튼으로 테스터 추가
2. 테스트용 Apple ID 생성
```

## 🚀 배포 전 체크리스트

### 코드 수정 사항

#### 1. 개발 모드 비활성화
```dart
// lib/services/purchase_service.dart
static const bool isDevelopmentMode = false; // true → false로 변경
```

#### 2. 애드몹 ID 확인
```dart
// lib/services/ad_service.dart
// 실제 ID가 올바르게 설정되어 있는지 확인
static String get interstitialAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-2803803669720807/1723563018';
  } else if (Platform.isIOS) {
    return 'ca-app-pub-2803803669720807/1723563018';
  }
}
```

#### 3. 앱 서명 설정
- **Android**: Play Console에서 앱 서명 키 생성
- **iOS**: Xcode에서 Provisioning Profile 설정

## 🧪 테스트 방법

### 개발 모드 테스트 (현재)
1. `isDevelopmentMode = true` 상태에서 테스트
2. 구매 버튼 클릭 → 1초 후 광고 제거 완료
3. 앱 재시작 후 광고 제거 상태 유지 확인

### 실제 스토어 테스트
1. 테스트 계정으로 앱 설치
2. 인앱 구매 테스트 (실제 결제 안됨)
3. 구매 복원 기능 테스트

## 📋 배포 단계

### 1. Android (Google Play)
```bash
# 1. 릴리즈 빌드
flutter build appbundle --release

# 2. Play Console에 업로드
# android/app/build/outputs/bundle/release/app-release.aab

# 3. 내부 테스트 → 비공개 테스트 → 프로덕션
```

### 2. iOS (App Store)
```bash
# 1. 릴리즈 빌드
flutter build ios --release

# 2. Xcode에서 Archive
# 3. App Store Connect에 업로드
# 4. TestFlight → App Store 심사
```

## ⚠️ 주의사항

1. **상품 ID 일치**: Android와 iOS에서 동일한 상품 ID 사용
2. **테스트 완료**: 실제 결제 전 충분한 테스트 필요
3. **개발 모드 비활성화**: 배포 전 반드시 `isDevelopmentMode = false`
4. **광고 정책 준수**: 애드몹 정책 위반 주의
5. **개인정보 처리방침**: 스토어 등록 시 필수

## 🔧 문제 해결

### 인앱 구매가 작동하지 않는 경우
1. 상품 ID 확인
2. 스토어에서 상품 활성화 상태 확인
3. 테스트 계정 설정 확인
4. 앱 서명 확인

### 광고가 표시되지 않는 경우
1. 애드몹 계정 상태 확인
2. 광고 단위 ID 확인
3. 앱 ID 확인
4. 네트워크 연결 확인 