# Flutter 관련 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Mobile Ads 관련 규칙
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# In-App Purchase 관련 규칙
-keep class com.android.billingclient.api.** { *; }

# SharedPreferences 관련 규칙
-keep class android.content.SharedPreferences { *; }

# Play Core 라이브러리 관련 규칙
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# 일반적인 최적화 방지 규칙
-dontwarn com.google.android.gms.**
-dontwarn com.android.billingclient.api.**

# 추가 Flutter 관련 규칙
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.** 