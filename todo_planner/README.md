# 🎯 습관메이커 (Habit Maker)

매일 반복하는 습관을 만들고 관리하는 Flutter 앱입니다.

## ✨ 주요 기능

- 📝 **습관 템플릿**: 최대 30개의 일일 습관 설정
- ✅ **일일 체크**: 간편한 체크리스트로 습관 관리
- 📊 **통계 및 분석**: 완료율과 성취 칭호 시스템
- 🔔 **스마트 알림**: 하루 3회 자동 알림 (8시, 13시, 18시)
- 💾 **자동 백업**: 안전한 데이터 보호
- 🌍 **다국어 지원**: 한국어, 영어, 일본어

## 🚀 시작하기

### 필수 요구사항

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK (API 21+)

### 설치 및 실행

1. **저장소 클론**
```bash
git clone https://github.com/YOUR_USERNAME/todo-planner-app.git
cd todo-planner-app/todo_planner
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **앱 실행**
```bash
flutter run
```

## 🔐 출시용 빌드 설정

### 1. 키스토어 설정

출시용 APK/AAB를 빌드하려면 키스토어 설정이 필요합니다:

```bash
# 1. 키스토어 설정 파일 생성
cp android/key.properties.template android/key.properties

# 2. key.properties 파일 편집
# 실제 키스토어 정보로 수정하세요
```

### 2. 키스토어 파일 생성

```bash
# 새 키스토어 생성 (한 번만 실행)
keytool -genkey -v -keystore android/habit-maker-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias habit-maker
```

### 3. 출시용 빌드

```bash
# AAB 파일 생성 (구글 플레이 스토어용)
flutter build appbundle --release

# APK 파일 생성 (직접 배포용)
flutter build apk --release
```

## 📱 앱 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
├── screens/                  # 화면 위젯
├── services/                 # 비즈니스 로직
│   ├── ad_service.dart      # 광고 관리
│   ├── notification_service.dart # 알림 관리
│   ├── backup_service.dart  # 백업/복원
│   └── storage_service.dart # 데이터 저장
├── l10n/                    # 다국어 지원
└── widgets/                 # 공통 위젯
```

## 🔒 보안 주의사항

⚠️ **중요**: 다음 파일들은 절대 GitHub에 업로드하지 마세요!

- `android/key.properties` - 키스토어 설정
- `*.jks`, `*.keystore` - 키스토어 파일
- `android/app/google-services.json` - Firebase 설정

이 파일들은 `.gitignore`에 포함되어 있습니다.

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 연락처

- 이메일: wjb127@naver.com
- 개인정보 처리방침: [Privacy Policy](https://wjb127.github.io/todo-planner-app/privacy-policy)

---

**Made with ❤️ by Habit Maker Team**
