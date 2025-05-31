# 🚀 습관메이커 구글 플레이스토어 출시 가이드

## 📋 출시 전 체크리스트

### 1. 코드 수정 사항
- [ ] `lib/services/purchase_service.dart`에서 `isDevelopmentMode = false`로 변경
- [ ] 애드몹 ID가 실제 ID로 설정되어 있는지 확인
- [ ] 앱 버전 정보 확인 (`pubspec.yaml`의 version)

### 2. 필수 파일 준비

#### 앱 아이콘
- [ ] `android/app/src/main/res/mipmap-*` 폴더에 아이콘 파일들 준비
- [ ] 권장 크기: 48x48, 72x72, 96x96, 144x144, 192x192dp

#### 스크린샷 (필수)
- [ ] 휴대전화용: 최소 2개, 최대 8개 (16:9 또는 9:16 비율)
- [ ] 크기: 320px ~ 3840px (긴 쪽 기준)
- [ ] 형식: JPEG 또는 24비트 PNG

#### 그래픽 에셋
- [ ] 고해상도 아이콘: 512x512px (PNG, 32비트)
- [ ] 기능 그래픽: 1024x500px (JPEG 또는 24비트 PNG)

## 🔧 빌드 및 서명

### 1. 키스토어 생성
```bash
keytool -genkey -v -keystore ~/habit-maker-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias habit-maker
```

### 2. key.properties 파일 생성
`android/key.properties` 파일 생성:
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=habit-maker
storeFile=../habit-maker-key.jks
```

### 3. build.gradle 수정
`android/app/build.gradle`에 서명 설정 추가:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 4. 릴리즈 빌드 생성
```bash
flutter build appbundle --release
```

## 📱 Google Play Console 설정

### 1. 개발자 계정 생성
1. [Google Play Console](https://play.google.com/console) 접속
2. 개발자 계정 생성 (일회성 등록비 $25)
3. 개발자 프로필 작성

### 2. 앱 생성
1. "앱 만들기" 클릭
2. 앱 세부정보 입력:
   - **앱 이름**: 습관메이커
   - **기본 언어**: 한국어
   - **앱 또는 게임**: 앱
   - **무료 또는 유료**: 무료

### 3. 앱 콘텐츠 설정

#### 개인정보처리방침
```
습관메이커 개인정보처리방침

1. 수집하는 개인정보
- 앱 사용 통계 (익명)
- 광고 식별자 (광고 표시용)

2. 개인정보 이용 목적
- 앱 서비스 제공
- 광고 표시
- 서비스 개선

3. 개인정보 보관 기간
- 앱 삭제 시까지

4. 문의처
- 이메일: [개발자 이메일]
```

#### 앱 카테고리
- **카테고리**: 생산성
- **태그**: 습관, 루틴, 생산성, 자기계발

#### 타겟 연령층
- **타겟 연령**: 13세 이상
- **연령 등급**: 모든 연령

### 4. 스토어 등록정보

#### 앱 설명
**간단한 설명 (80자 이내)**:
```
매일 반복하는 습관을 쉽게 만들고 관리하는 앱
```

**자세한 설명**:
```
🌟 습관메이커로 더 나은 나를 만들어보세요!

매일 반복하는 작은 습관들이 모여 큰 변화를 만듭니다. 습관메이커는 여러분의 일상 루틴을 체계적으로 관리하고 성취감을 느낄 수 있도록 도와드립니다.

✨ 주요 기능
• 반복 습관 템플릿: 최대 30개의 습관을 설정하고 드래그로 순서 변경
• 일일 체크: 날짜별로 습관 완료 상황을 체크하고 진행률 확인
• 통계 및 칭호: 30일간 완료율 분석과 12단계 성취 칭호 시스템
• 매일 8시 알림: 다양한 동기부여 메시지로 습관 체크 알림
• 깔끔한 UI: 현대적이고 직관적인 인디고 테마 디자인

🎯 이런 분들께 추천
• 규칙적인 생활 습관을 만들고 싶은 분
• 운동, 독서, 물 마시기 등 꾸준히 하고 싶은 일이 있는 분
• 목표 달성을 위해 체계적인 관리가 필요한 분
• 성취감과 동기부여를 얻고 싶은 분

🏆 특별한 칭호 시스템
완료율에 따라 '완벽주의자'부터 '잠자는 자'까지 12단계 칭호를 획득하세요!

📊 상세한 통계
최근 30일간의 습관 완료율을 그래프와 표로 한눈에 확인하고, 항목별 성과를 분석해보세요.

지금 시작해서 더 나은 내일을 만들어보세요! 🚀
```

#### 키워드
```
습관, 루틴, 생산성, 자기계발, 목표달성, 체크리스트, 일정관리, 라이프스타일
```

### 5. 앱 번들 업로드
1. "프로덕션" → "새 버전 만들기"
2. `build/app/outputs/bundle/release/app-release.aab` 파일 업로드
3. 출시 노트 작성:
```
🎉 습관메이커 첫 출시!

✨ 주요 기능
• 반복 습관 템플릿 관리 (최대 30개)
• 일일 습관 체크 및 진행률 확인
• 30일간 통계 및 성취 칭호 시스템
• 매일 8시 동기부여 알림
• 광고 제거 인앱결제 (₩11,000)

더 나은 습관, 더 나은 나를 만들어보세요! 🌟
```

## 🎯 마케팅 전략

### 1. ASO (앱 스토어 최적화)
- **키워드**: 습관, 루틴, 생산성, 자기계발
- **아이콘**: 명확하고 기억하기 쉬운 디자인
- **스크린샷**: 주요 기능을 보여주는 매력적인 이미지

### 2. 초기 사용자 확보
- 지인들에게 앱 공유 및 리뷰 요청
- 소셜미디어 홍보
- 관련 커뮤니티에 소개

### 3. 사용자 피드백 수집
- 리뷰 모니터링
- 기능 개선 사항 수집
- 정기적인 업데이트

## 📈 출시 후 관리

### 1. 모니터링 지표
- 다운로드 수
- 사용자 유지율
- 크래시 리포트
- 사용자 리뷰

### 2. 업데이트 계획
- 버그 수정
- 새로운 기능 추가
- 사용자 요청 사항 반영

### 3. 수익화 최적화
- 광고 성과 분석
- 인앱결제 전환율 개선
- 새로운 프리미엄 기능 검토

## ⚠️ 주의사항

1. **개인정보처리방침**: 반드시 웹사이트에 게시 필요
2. **연령 등급**: 광고 내용에 따라 등급 조정 필요
3. **정책 준수**: Google Play 정책 위반 주의
4. **테스트**: 내부 테스트 → 비공개 테스트 → 프로덕션 순서로 진행
5. **백업**: 키스토어 파일 안전하게 보관

## 📞 지원

출시 과정에서 문제가 발생하면:
- [Google Play Console 고객센터](https://support.google.com/googleplay/android-developer/)
- [Flutter 공식 문서](https://docs.flutter.dev/deployment/android)
- 개발자 커뮤니티 문의

---

**성공적인 출시를 위해 체크리스트를 하나씩 완료해주세요! 🎉** 