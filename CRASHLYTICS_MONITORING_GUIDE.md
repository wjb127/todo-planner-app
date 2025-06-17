# 🚨 Firebase Crashlytics 모니터링 및 크래시 대응 가이드

## 📋 개요
Firebase Crashlytics에서 크래시가 감지되었을 때의 분석, 수정, 업데이트 배포 프로세스를 안내합니다.

## 🔄 **크래시 대응 프로세스**

### 1️⃣ **크래시 감지 및 알림**
```
Firebase Console 이메일 알림 수신
↓
즉시 Firebase Console → Crashlytics 대시보드 확인
↓
심각도 및 영향 범위 분석
```

### 2️⃣ **크래시 분석**
- **영향받는 사용자 수**: 몇 명의 사용자가 영향을 받았는가?
- **크래시 빈도**: 얼마나 자주 발생하는가?
- **기기 및 OS 정보**: 특정 기기나 Android 버전에서만 발생하는가?
- **스택 트레이스**: 정확한 오류 위치는 어디인가?

### 3️⃣ **우선순위 분류**

#### 🔴 **긴급 (즉시 수정)**
- 앱 강제 종료 크래시
- 50% 이상 사용자 영향
- 핵심 기능 완전 마비

#### 🟡 **높음 (48시간 내 수정)**
- 주요 기능 일부 오작동
- 10-50% 사용자 영향
- 특정 기기/OS에서 반복 발생

#### 🟢 **보통 (다음 업데이트에 포함)**
- 비핵심 기능 오류
- 10% 미만 사용자 영향
- 가끔씩 발생하는 오류

### 4️⃣ **수정 및 테스트**
```bash
# 1. 코드 수정
# 2. 로컬 테스트
flutter test

# 3. 디버그 빌드로 테스트
flutter run --debug

# 4. 릴리즈 빌드로 최종 테스트
flutter build apk --release
flutter install build/app/outputs/flutter-apk/app-release.apk
```

### 5️⃣ **업데이트 배포**
```bash
# 1. 버전 업데이트 (pubspec.yaml)
version: 1.0.2+2  # 버전명+빌드번호

# 2. AAB 빌드 (플레이 스토어용)
flutter build appbundle --release

# 3. 구글 플레이 콘솔 업로드
# build/app/outputs/bundle/release/app-release.aab
```

## 📊 **실제 크래시 예시 및 대응**

### **예시 1: 널 포인터 예외**
```
🔴 크래시 정보:
Fatal Exception: java.lang.NullPointerException
at com.habitmaker.app.StorageService.loadTemplate(StorageService.dart:45)

영향: 신규 사용자 20명 (템플릿이 없는 상태에서 앱 실행)
우선순위: 긴급
```

**수정 방법:**
```dart
// 수정 전 (크래시 발생)
final templateList = jsonDecode(templateJson);  // templateJson이 null일 때 크래시

// 수정 후 (안전한 처리)
if (templateJson == null) {
  return [];  // 빈 리스트 반환
}
final templateList = jsonDecode(templateJson);
```

### **예시 2: 네트워크 타임아웃**
```
⚠️ 비치명적 오류:
SocketTimeoutException: 광고 로딩 시간 초과
at AdService.loadInterstitialAd(AdService.dart:120)

영향: 인터넷이 느린 사용자들 (5% 정도)
우선순위: 보통
```

**수정 방법:**
```dart
// 수정 전
InterstitialAd.load(adUnitId: adUnitId);

// 수정 후 (재시도 로직 추가)
try {
  InterstitialAd.load(adUnitId: adUnitId);
} catch (e) {
  // 5초 후 재시도
  Future.delayed(Duration(seconds: 5), () {
    _retryLoadAd();
  });
}
```

## 🛠️ **개발자 도구 및 팁**

### **Firebase Console에서 확인할 정보**
1. **Issue 탭**: 크래시 종류별 그룹화
2. **Velocity**: 크래시 증가/감소 추이
3. **Versions**: 버전별 크래시 비교
4. **Devices**: 기기별 크래시 분포

### **코드에서 예방적 모니터링**
```dart
// 중요한 기능에 미리 오류 처리 추가
try {
  // 위험할 수 있는 작업
  await criticalFunction();
} catch (e, stackTrace) {
  // Crashlytics에 기록
  await FirebaseService.recordError(
    e,
    stackTrace,
    reason: 'criticalFunction 실행 중 오류',
    fatal: false,
  );
  
  // 사용자에게 친화적인 메시지 표시
  showUserFriendlyError();
}
```

### **사용자 정보 추가** (디버깅에 도움)
```dart
// 사용자 식별자 설정
await FirebaseService.setUserId('user_${uniqueId}');

// 커스텀 키 설정
await FirebaseService.setCustomKey('app_version', '1.0.2');
await FirebaseService.setCustomKey('user_type', 'premium');
await FirebaseService.setCustomKey('templates_count', '5');
```

## 📱 **구글 플레이 스토어 업데이트 과정**

### **1단계: 앱 준비**
```bash
# pubspec.yaml에서 버전 업데이트
version: 1.0.2+2

# AAB 빌드
flutter build appbundle --release
```

### **2단계: 플레이 콘솔 업로드**
1. [Google Play Console](https://play.google.com/console) 접속
2. "프로덕션" → "새 버전 만들기"
3. AAB 파일 업로드: `build/app/outputs/bundle/release/app-release.aab`
4. 출시 노트 작성:
   ```
   버전 1.0.2 업데이트 내용:
   - 앱 시작 시 발생하던 크래시 문제 수정
   - 안정성 개선
   - 버그 수정
   ```

### **3단계: 단계적 출시**
- **첫 배포**: 1% 사용자에게만 (테스트)
- **문제없으면**: 10% → 50% → 100% 단계적 확대
- **문제 발생시**: 즉시 롤백 가능

## ⚡ **긴급 크래시 대응 체크리스트**

### **즉시 해야 할 일 (30분 내)**
- [ ] Firebase Console에서 크래시 상세 정보 확인
- [ ] 영향받는 사용자 수 파악
- [ ] 스택 트레이스에서 정확한 오류 위치 확인
- [ ] 로컬에서 재현 가능한지 테스트

### **빠른 수정 (2시간 내)**
- [ ] 코드 수정 완료
- [ ] 로컬 테스트 완료
- [ ] 릴리즈 빌드 테스트 완료
- [ ] AAB 빌드 완료

### **배포 (4시간 내)**
- [ ] 플레이 콘솔에 업로드
- [ ] 출시 노트 작성
- [ ] 1% 단계적 출시 시작
- [ ] Firebase Console에서 새 버전 크래시 모니터링

## 📈 **성과 측정**

### **수정 성공 지표**
- 해당 크래시 발생 빈도 0%로 감소
- 전체 크래시 free 사용자 비율 증가
- 앱 평점 유지 또는 상승

### **모니터링 주기**
- **실시간**: 긴급 크래시 알림
- **일일**: 전체 크래시 동향 확인
- **주간**: 버전별 안정성 비교
- **월간**: 전체 품질 지표 리뷰

---

**💡 핵심 원칙: 사용자 경험을 최우선으로, 빠른 대응과 예방적 모니터링!** 