# 🍎 iOS Firebase 설정 체크리스트

## 📋 **현재 상태**
- ✅ Android Firebase 설정 완료
- ✅ iOS Podfile에 Firebase 의존성 추가됨
- ✅ iOS AppDelegate에 Firebase 초기화 코드 추가됨
- ⏳ **다음 단계들 진행 필요**

## 🚀 **Step 1: Firebase Console에서 iOS 앱 추가**

### 📱 Firebase Console 작업
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 기존 **Habit Maker** 프로젝트 선택 (Android와 동일한 프로젝트)
3. 프로젝트 설정 (⚙️ 아이콘) → "내 앱" 섹션
4. **"앱 추가"** 버튼 → **iOS** 선택

### 📝 앱 등록 정보 입력
```
iOS 번들 ID: com.habitmaker.app
앱 닉네임: Habit Maker iOS  
App Store ID: (나중에 추가 - 지금은 비워두기)
```

### 📁 GoogleService-Info.plist 다운로드
1. **"GoogleService-Info.plist 다운로드"** 클릭
2. 파일을 안전한 곳에 저장 (Desktop 등)
3. **⚠️ 주의**: 이 파일은 민감한 정보를 포함하므로 Git에 커밋하지 마세요!

---

## 🚀 **Step 2: Xcode에서 GoogleService-Info.plist 추가**

### 📱 Xcode 작업
1. **터미널에서 Xcode 열기**:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Xcode에서 파일 추가**:
   - 왼쪽 프로젝트 탐색기에서 **"Runner"** 폴더 선택
   - 우클릭 → **"Add Files to Runner"**
   - 다운로드한 **GoogleService-Info.plist** 파일 선택
   - ✅ **"Copy items if needed"** 체크
   - ✅ **"Add to target: Runner"** 체크
   - **"Add"** 클릭

3. **파일 위치 확인**:
   - `ios/Runner/GoogleService-Info.plist`에 파일이 있어야 함
   - Xcode 프로젝트 탐색기에서도 파일이 보여야 함

---

## 🚀 **Step 3: iOS 의존성 설치**

### 📱 CocoaPods 설치
```bash
# iOS 폴더로 이동
cd ios

# 기존 Pods 폴더 삭제 (클린 설치)
rm -rf Pods
rm Podfile.lock

# Pod 의존성 설치
pod install
```

### ✅ 설치 성공 확인
설치가 성공하면 다음과 같은 메시지가 나타납니다:
```
Pod installation complete! There are X dependencies from the Podfile and Y total pods installed.
```

---

## 🚀 **Step 4: iOS 앱 빌드 및 테스트**

### 📱 Flutter iOS 빌드
```bash
# 프로젝트 루트로 돌아가기
cd ..

# iOS 시뮬레이터에서 앱 실행
flutter run -d ios
```

### 🧪 Firebase 기능 테스트
1. **앱 실행 후 설정 화면 이동**
2. **"Firebase 테스트" 섹션** 찾기
3. **각 테스트 버튼 사용**:
   - 🔍 **"로그 테스트"**: Firebase 로깅 테스트
   - ⚠️ **"오류 테스트"**: 비치명적 오류 기록 테스트
   - 💥 **"크래시 테스트"**: 앱 크래시 테스트

### 📊 Firebase Console에서 확인
1. [Firebase Console](https://console.firebase.google.com/) → 프로젝트 선택
2. **Crashlytics** 섹션 확인:
   - iOS 앱에서 발생한 이벤트들이 나타나야 함
   - 테스트 크래시가 기록되었는지 확인

---

## 🚀 **Step 5: 실제 iOS 기기에서 테스트** (선택사항)

### 📱 실제 기기 연결 테스트
```bash
# 연결된 iOS 기기 확인
flutter devices

# 실제 기기에서 실행 (기기 ID 사용)
flutter run -d [기기ID]

# 또는 릴리즈 모드로 실행
flutter run -d [기기ID] --release
```

**⚠️ 주의**: 실제 기기에서 실행하려면 Apple 개발자 계정과 서명 설정이 필요합니다.

---

## 📋 **완료 체크리스트**

### ✅ Firebase Console
- [ ] iOS 앱이 Firebase 프로젝트에 추가됨
- [ ] GoogleService-Info.plist 다운로드 완료
- [ ] Crashlytics가 iOS 플랫폼에서 활성화됨

### ✅ Xcode 프로젝트
- [ ] GoogleService-Info.plist가 Runner 타겟에 추가됨
- [ ] 파일이 `ios/Runner/` 폴더에 위치함
- [ ] Xcode에서 파일이 프로젝트에 포함되어 보임

### ✅ 의존성 설치
- [ ] `pod install` 명령어 성공 실행
- [ ] `ios/Pods/` 폴더 생성됨
- [ ] Firebase 관련 Pod들이 설치됨

### ✅ 앱 테스트
- [ ] iOS 시뮬레이터에서 앱 실행 성공
- [ ] Firebase 테스트 기능들이 정상 작동
- [ ] Firebase Console에서 iOS 앱 데이터 확인

---

## ⚠️ **문제 해결**

### 🚫 자주 발생하는 문제들

#### **1. "No such module 'Firebase'" 오류**
```bash
# 해결방법: Pod 재설치
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run -d ios
```

#### **2. GoogleService-Info.plist 찾을 수 없음**
- Xcode에서 파일이 Runner 타겟에 추가되었는지 확인
- 파일이 `ios/Runner/` 폴더에 실제로 존재하는지 확인

#### **3. 빌드 실패**
```bash
# 전체 클린 빌드
flutter clean
cd ios
pod install
cd ..
flutter run -d ios
```

#### **4. Firebase Console에 데이터가 안 보임**
- 앱을 실제로 사용해보고 5-10분 정도 기다리기
- 릴리즈 모드로 빌드해서 테스트해보기

---

## 📱 **최종 확인**

모든 설정이 완료되면:
1. **Android와 iOS 모두** Firebase Console에서 데이터 수집 중
2. **통합 대시보드**에서 두 플랫폼 모니터링 가능
3. **크래시 및 오류**가 실시간으로 수집됨
4. **플랫폼별 비교** 분석 가능

**🎉 iOS Firebase 설정 완료 후 멀티플랫폼 모니터링 시작!** 