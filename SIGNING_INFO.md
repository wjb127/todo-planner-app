# 🔐 앱 서명 정보 (수정됨)

## 키스토어 정보
- **파일명**: `habit-maker-key.jks`
- **키 별칭**: `habit-maker`
- **스토어 비밀번호**: `habitmaker2024`
- **키 비밀번호**: `habitmaker2024`
- **유효기간**: 2025년 6월 1일 ~ 2052년 10월 17일 (27년)

## 인증서 정보
- **발행자**: CN=Habit Maker, OU=Development, O=Habit Maker Team, L=Seoul, ST=Seoul, C=KR
- **서명 알고리즘**: SHA256withRSA
- **키 크기**: 2048-bit
- **인증서 체인**: ✅ 단일 체인 (구글 플레이 콘솔 호환)

## 출시용 파일들
- **최종 서명된 AAB**: `build/app/outputs/bundle/release/app-release.aab` (31.3MB)
- **키스토어 파일**: `android/habit-maker-key.jks` (2.8KB)

## 문제 해결 완료 ✅
- ❌ **이전 문제**: "인증서 체인이 2개 이상 포함되어 있습니다"
- ✅ **해결 방법**: debug 서명 제거, release 서명만 사용
- ✅ **결과**: 단일 인증서 체인으로 깔끔하게 서명됨

## 구글 플레이 콘솔 업로드 준비 완료
1. 구글 플레이 콘솔에 로그인
2. "프로덕션" → "새 버전 만들기"
3. `app-release.aab` 파일 업로드 ✅
4. 출시 노트 작성 및 검토 후 출시

## 보안 주의사항
⚠️ **중요**: 키스토어 파일과 비밀번호는 안전한 곳에 보관하세요!
- 키스토어 파일을 분실하면 앱 업데이트가 불가능합니다
- 비밀번호를 잊어버리면 새로운 앱으로 출시해야 합니다
- 키스토어는 백업을 여러 곳에 보관하는 것을 권장합니다

## 파일 위치
```
todo_planner/
├── android/habit-maker-key.jks               # 키스토어 파일
├── android/key.properties                    # 키스토어 설정 (사용 안 함)
└── build/app/outputs/bundle/release/
    └── app-release.aab                       # 최종 서명된 AAB ✅
```

## 빌드 설정
- **서명 방식**: build.gradle에 직접 하드코딩
- **키스토어 경로**: `../habit-maker-key.jks` (android/app 기준)
- **서명 검증**: ✅ 통과 (단일 인증서 체인) 