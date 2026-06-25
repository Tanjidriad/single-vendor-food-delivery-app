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

# Mapbox
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# Firebase / FCM
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Socket.IO / engine.io — uses reflection to instantiate packet types
-keep class io.socket.** { *; }
-dontwarn io.socket.**
-keep class org.json.** { *; }

# flutter_secure_storage — uses Android Keystore via reflection
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Google Play Core — Flutter's embedding references the deferred-components /
# split-install APIs, but we don't bundle Play Core. R8 errors on the missing
# classes; we don't use deferred components, so it's safe to ignore them.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
