# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*

# OkHttp / Retrofit (if used by plugins)
-dontwarn okhttp3.**
-dontwarn okio.**

# Firebase / FCM
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Sunmi printer SDK
-keep class com.sunmi.** { *; }
-dontwarn com.sunmi.**
