## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
}

## flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class com.google.firebase.** { *; }

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Keep generic signature for gson
-keepattributes Signature

## Keep notification channels and other reflection-based classes
-keep class * extends java.lang.Enum { *; }

## Google Play Core (for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

## Keep custom alarm classes
-keep class com.example.notify_tester.AlarmReceiver { *; }
-keep class com.example.notify_tester.AlarmActivity { *; }
-keep class com.example.notify_tester.AlarmService { *; }
-keep class com.example.notify_tester.MainActivity { *; }

## Keep all BroadcastReceivers
-keep public class * extends android.content.BroadcastReceiver

## Keep AlarmManager related classes
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }

## Keep all public methods in custom classes
-keepclassmembers class com.example.notify_tester.** {
    public *;
}

## Keep Intent extras
-keepclassmembers class * {
    public void onReceive(android.content.Context, android.content.Intent);
}

## Keep method channel handlers
-keepclassmembers class * {
    *** configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine);
}
