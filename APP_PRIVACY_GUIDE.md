# 📱 App Store Connect - App Privacy 설정 가이드

## 🔒 **개인정보 보호 설정**

### **1단계: 데이터 수집 여부**
**질문**: Does this app collect data?
**답변**: **No** ✅

**이유**: 
- 모든 데이터는 기기에만 저장됨
- 서버로 개인정보 전송 없음
- 사용자 추적 없음
- 광고 ID만 사용 (개인정보 아님)

### **2단계: 데이터 사용 목적 (해당 없음)**
데이터를 수집하지 않으므로 이 섹션은 건너뜀

### **3단계: 데이터 연결 (해당 없음)**
데이터를 수집하지 않으므로 이 섹션은 건너뜀

### **4단계: 데이터 추적 (해당 없음)**
사용자를 추적하지 않으므로 이 섹션은 건너뜀

## 📋 **설정 요약**

```
Data Collection: No
Third-Party Data: No
Tracking: No
Contact Info: No
Health & Fitness: No
Financial Info: No
Location: No
Sensitive Info: No
Contacts: No
User Content: No
Browsing History: No
Search History: No
Identifiers: No
Usage Data: No
Diagnostics: No
Other Data: No
```

## ✅ **완료 후 확인사항**

1. **Privacy Policy URL**: https://wjb127.github.io/todo-planner-app/
2. **Contact Information**: 개발자 연락처 입력 완료
3. **App Privacy**: "No data collected" 설정 완료
4. **Build**: IPA 파일 업로드 및 선택 완료

## 🚨 **주의사항**

- **광고 표시**는 개인정보 수집이 아님
- **기기 내 저장**은 개인정보 수집이 아님
- **AdMob 광고 ID**는 개인정보가 아님 (익명 식별자)
- **알림 권한**은 개인정보 수집이 아님

## 📞 **Admin 권한 문제 해결**

만약 Admin 권한이 없다면:
1. **Users and Access** → **Users** 탭
2. **본인 계정의 Role 확인**
3. **Admin** 또는 **App Manager** 권한 필요
4. **Account Holder**에게 권한 요청 