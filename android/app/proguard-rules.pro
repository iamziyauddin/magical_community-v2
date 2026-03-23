# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Dio HTTP client
-keep class dio.** { *; }
-dontwarn okio.**
-dontwarn retrofit2.**

# JSON serialization
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep model classes
-keep class com.mindmesh.magicalcommunity.models.** { *; }
-keep class com.mindmesh.magicalcommunity.data.** { *; }

# General
-dontwarn java.lang.invoke.StringConcatFactory
